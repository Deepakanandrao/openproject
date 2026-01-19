import { vi, beforeAll, describe, expect, test } from "vitest";
import { secret } from "../../src/services/digestSecretService";;

describe("secret", () => {
  describe("when the env is not defined", () => {
    beforeAll(() => {
      vi.stubEnv("SECRET", undefined);
    });

    test("should throw an error if SECRET is not defined", () => {
      expect(() => secret()).toThrowError("SECRET environment variable is not set.");
    });
  });

  describe("when the env is defined", () => {
    beforeAll(() => {
      vi.stubEnv("SECRET", "secret12345");
    });

    test("should transform the value", () => {
      const digest = secret();
      expect(digest).not.toBe("secret12345");
    });

    test("should sha256 digest the SECRET value defined in env", () => {
      const digest = secret();
      expect(digest).toEqual(Buffer.from([
        25, 43, 47, 83, 211, 117, 19, 173, 228,
        152, 238, 124, 243, 23, 126, 15, 194, 31,
        37, 141, 171, 255, 62, 157, 134, 213, 72,
        182, 56, 86, 147, 161,
      ]));
    });
  });
});
