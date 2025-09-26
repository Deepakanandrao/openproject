import { Extension } from "@hocuspocus/server";
import { createVerifier } from 'fast-jwt';
import type { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import type { ApiResponseDocument, OpenProjectApiConfiguration } from "../types";
import * as Y from "yjs";

const secret = process.env.SECRET;
if (!secret) {
  console.log(`SECRET must be provided`);
  process.exit();
};

const verifyToken = createVerifier({ key: async () => secret, algorithms: ['HS256'] });

// my local dev env key, it's not a leak :)
const RAW_KEY = "9e4cb47e0b0dbe407dddd6d022314ee3f9ac147856a15cc3d6d55b2e54fd2fa6";
const API_KEY = Buffer.from(`apikey:${RAW_KEY}`, "utf-8").toString("base64");

export class OpenProjectApi implements Extension {
  configuration: OpenProjectApiConfiguration = {
    apiUrl: "https://openproject.local",
    token: "",
  };

  constructor(configuration: OpenProjectApiConfiguration) {
    this.configuration = {
      ...this.configuration,
      ...configuration
    };
  }

  async onAuthenticate(data: onAuthenticatePayload) {
    const { token, documentName } = data;
    if (!token) {
      throw new Error('Unauthorized: Token missing.');
    }
    let tokenPayload;
    try {
      tokenPayload = await verifyToken(token);
    } catch (_err) {
      throw new Error('Unauthorized: Invalid token.');
    }
    if(documentName != tokenPayload.document_name) {
      throw new Error('Unauthorized: This document cannot be accessed with this token.');
    }
    data.context.documentId = tokenPayload.document_id;
  }

  /**
    * Retrieve data from the API. This should return the YDoc data
    */
  async onLoadDocument(data: onLoadDocumentPayload) {
    const { documentId } = data.context;

    const targetUrl = `${this.configuration.apiUrl}/api/v3/documents/${documentId}`;
    console.log(`GET ${targetUrl}`);

    const response = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${API_KEY}`,
      },
    });

    if (!response.ok) {
      console.warn(`Error fetching document: ${response.statusText}`);
      return;
    }

    const jsonData = await response.json() as ApiResponseDocument;
    if (jsonData.contentBinary) {
      const update = new Uint8Array(Buffer.from(jsonData.contentBinary, 'base64'));
      Y.applyUpdate(data.document, update);
    }
  }

  /**
    * Store data to the API. The data is a YDoc update
    */
  async onStoreDocument(data: onStoreDocumentPayload): Promise<void> {
    const { documentId } = data.context;

    const targetUrl = `${this.configuration.apiUrl}/api/v3/documents/${documentId}`;
    console.log(`PATCH ${targetUrl}`);

    const base64Data = Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64");

    const response = await fetch(targetUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${API_KEY}`,
      },
      body: JSON.stringify({
        content_binary: base64Data
      }),
    });

    if (!response.ok) {
      console.warn(`Error storing document: ${response.statusText}`);
    }
  }
}

