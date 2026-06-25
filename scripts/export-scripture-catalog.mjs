#!/usr/bin/env node
/**
 * Export SpiritualPassageCatalog scripture entries to scripture-catalog.json
 * for the chaplain-chat edge function.
 *
 * Usage: node scripts/export-scripture-catalog.mjs
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const swiftPath = path.join(root, "DevotionLock/Models/SpiritualPassageCatalog.swift");
const outPath = path.join(root, "supabase/functions/_shared/scripture-catalog.json");

const swift = fs.readFileSync(swiftPath, "utf8");

const entryRe =
  /SpiritualPassage\(id:\s*"([^"]+)",\s*text:\s*"((?:\\.|[^"\\])*)",\s*reference:\s*"((?:\\.|[^"\\])*)",\s*source:\s*\.(\w+)(?:,\s*author:\s*(?:nil|"((?:\\.|[^"\\])*)"))?,\s*topics:\s*\[([^\]]+)\]\)/g;

const passages = [];
let match;
while ((match = entryRe.exec(swift)) !== null) {
  const [, id, text, reference, source, author, topicsRaw] = match;
  const topics = [...topicsRaw.matchAll(/\.(\w+)/g)].map((m) => m[1]);
  passages.push({
    id,
    text: text.replace(/\\"/g, '"'),
    reference: reference.replace(/\\"/g, '"'),
    source,
    author: author ? author.replace(/\\"/g, '"') : null,
    topics,
  });
}

const payload = {
  generatedAt: new Date().toISOString(),
  version: 1,
  passages,
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(payload, null, 2) + "\n");
console.log(`Wrote ${passages.length} passages → ${outPath}`);
