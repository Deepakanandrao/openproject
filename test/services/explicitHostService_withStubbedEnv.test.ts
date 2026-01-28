import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { replaceWithExplicitHost } from "../../src/services/explicitHostService";

describe("replaceWithExplicitHost with stubbed env", () => {
  beforeAll(() => {
    vi.hoisted(() => {
      vi.stubEnv("OPENPROJECT_DIRECT_URL", "https://my-custom.com/hocuspocus");
    });
  });

  afterAll(() => {
    vi.unstubAllEnvs();
  });

  test("replaces the hostname with the explicit host", () => {
    const resourceUrl = "https://example.com/path/to/resource";
    const result = replaceWithExplicitHost(resourceUrl);
    expect(result).toBe("https://my-custom.com/hocuspocus/path/to/resource");
  });
});
