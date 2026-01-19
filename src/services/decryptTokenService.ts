import { createDecipheriv } from "node:crypto";
import * as DigestSecretService from "./digestSecretService";

const ALGORITHM = "aes-256-gcm";
 
/**
 * Decrypts a given token using AES-256-GCM algorithm.
 */
export function decryptToken(encrypted:string):string {
  const [token, iv, authTag] = encrypted.split('--').map((part:string) => Buffer.from(part, 'base64'));

  const decipher = createDecipheriv(ALGORITHM, DigestSecretService.secret(), iv);
  decipher.setAuthTag(authTag);

  const decrypted = Buffer.concat([
    decipher.update(token),
    decipher.final()
  ]);
  
  return decrypted.toString();
}
