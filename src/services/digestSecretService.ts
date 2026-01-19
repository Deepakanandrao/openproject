import { createHash } from "node:crypto";

/**
 * Generates a SHA-256 digest of the SECRET environment variable.
 */
export function secret() {
  if (!process.env.SECRET) {
    throw new Error("SECRET environment variable is not set.");
  }

  const secretEnv = process.env.SECRET;
  return createHash("sha256").update(secretEnv).digest();
}
