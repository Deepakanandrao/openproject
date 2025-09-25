import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { onAuthenticatePayload } from "@hocuspocus/server";

describe("OpenProjectApi", () => {
  beforeAll(() => {
    vi.stubEnv("SECRET", "testSuperSecret1234");
  });

  afterAll(() => {
    vi.unstubAllEnvs();
  });

  describe("onAuthenticate", () => {
    test("when the token is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi({}).onAuthenticate({
          token: null,
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token missing.");
    });

    test("when the token has an invalid secret", async () => {
      /*
       * {
       *   "document_id": 121,
       *   "document_name": "TheDocName",
       *   "document_text": "empty except this"
       * }
       *
       * secret: "notTheSecret"
       */
      const tokenWithWrongSecret = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkb2N1bWVudF9pZCI6MTIxLCJkb2N1bWVudF9uYW1lIjoiVGhlRG9jTmFtZSIsImRvY3VtZW50X3RleHQiOiJlbXB0eSBleGNlcHQgdGhpcyJ9.ANskFI50S6eEji-s5IYp7tLtNsuYpzE8Xz7kzj9CmsE";

      await expect(() =>
        new OpenProjectApi({}).onAuthenticate({
          token: tokenWithWrongSecret
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid token.");
    });
  });
});
