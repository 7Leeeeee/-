import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

const inputPath = process.argv[2];
if (!inputPath) {
  throw new Error("Usage: node tools/make-import-code.mjs <schedule-envelope.json>");
}

const value = JSON.parse(await readFile(inputPath, "utf8"));
const sortDeep = (input) => {
  if (Array.isArray(input)) return input.map(sortDeep);
  if (input && typeof input === "object") {
    return Object.fromEntries(
      Object.keys(input)
        .sort()
        .map((key) => [key, sortDeep(input[key])]),
    );
  }
  return input;
};

const payload = Buffer.from(JSON.stringify(sortDeep(value)), "utf8");
const encoded = payload
  .toString("base64")
  .replaceAll("+", "-")
  .replaceAll("/", "_")
  .replace(/=+$/u, "");
const checksum = createHash("sha256").update(payload).digest("hex").slice(0, 12);

process.stdout.write(`MT1.${encoded}.${checksum}\n`);
