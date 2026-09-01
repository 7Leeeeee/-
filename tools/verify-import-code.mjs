import { createHash } from "node:crypto";

const code = process.argv[2]?.trim();
if (!code) throw new Error("Usage: node tools/verify-import-code.mjs <code>");
const [prefix, encoded, expected] = code.split(".");
if (prefix !== "MT1" || !encoded || !expected) throw new Error("Malformed import code");
const padding = "=".repeat((4 - (encoded.length % 4)) % 4);
const payload = Buffer.from(encoded.replaceAll("-", "+").replaceAll("_", "/") + padding, "base64");
const actual = createHash("sha256").update(payload).digest("hex").slice(0, 12);
if (actual !== expected.toLowerCase()) throw new Error("Checksum mismatch");
const value = JSON.parse(payload.toString("utf8"));
if (value.schemaVersion !== 1) throw new Error("Unsupported schema version");
process.stdout.write(
  JSON.stringify(
    {
      source: value.source,
      term: value.schedule.name,
      periods: value.schedule.periods.length,
      courseRecords: value.schedule.courses.length,
    },
    null,
    2,
  ) + "\n",
);
