/**
 * ScriptureCorpus — edge implementation for Chaplain tools.
 */

import catalog from "./scripture-catalog.json" with { type: "json" };
import { parseBibleReference } from "./bible-reference-parser.ts";

export interface ScripturePassage {
  reference: string;
  text: string;
  source: "bible_api" | "curated_catalog";
  book_slug?: string;
  chapter?: number;
  start_verse?: number;
  end_verse?: number;
  catalog_passage_id?: string;
  version?: string;
}

const BIBLE_API = "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles";
const DEFAULT_VERSION = "en-kjv";

interface BibleVerse {
  book: string;
  chapter: string;
  verse: string;
  text: string;
}

/** Keep first occurrence when the Bible API returns duplicate verse rows. */
function dedupeVersesByNumber(verses: BibleVerse[]): BibleVerse[] {
  const seen = new Set<string>();
  return verses.filter((v) => {
    if (seen.has(v.verse)) return false;
    seen.add(v.verse);
    return true;
  });
}

/** Collapse duplicate pilcrow segments and repeated sentences within joined text. */
export function normalizeScriptureText(text: string): string {
  let normalized = text.trim().replace(/\s+/g, " ");

  const pilcrowParts = normalized.split(/¶/).map((s) => s.trim()).filter(Boolean);
  if (pilcrowParts.length > 1) {
    const unique: string[] = [];
    for (const part of pilcrowParts) {
      if (!unique.some((u) => u === part)) unique.push(part);
    }
    normalized = unique.join(" ");
  }

  normalized = normalized.replace(/^¶\s*/, "");

  const sentences = normalized.match(/[^.!?]+[.!?]+|[^.!?]+$/g)?.map((s) => s.trim()).filter(Boolean) ?? [normalized];
  if (sentences.length > 1) {
    const uniqueSentences: string[] = [];
    for (const sentence of sentences) {
      if (!uniqueSentences.some((u) => u === sentence)) uniqueSentences.push(sentence);
    }
    normalized = uniqueSentences.join(" ");
  }

  return normalized.trim();
}

export async function lookupPassage(reference: string): Promise<ScripturePassage | null> {
  const parsed = parseBibleReference(reference);
  if (!parsed) return null;

  const url = `${BIBLE_API}/${DEFAULT_VERSION}/books/${parsed.bookSlug}/chapters/${parsed.chapter}.json`;
  const res = await fetch(url);
  if (!res.ok) return null;

  const body = await res.json() as { data?: BibleVerse[] };
  const verses = body.data ?? [];
  if (!verses.length) return null;

  let selected = dedupeVersesByNumber(verses);
  if (parsed.verse) {
    const end = parsed.endVerse ?? parsed.verse;
    selected = selected.filter((v) => {
      const n = Number(v.verse);
      return n >= parsed.verse! && n <= end;
    });
    if (!selected.length) selected = dedupeVersesByNumber(verses);
  }

  const text = normalizeScriptureText(selected.map((v) => v.text).join(" "));
  const start = Number(selected[0]?.verse);
  const end = Number(selected[selected.length - 1]?.verse);

  return {
    reference: parsed.displayReference,
    text,
    source: "bible_api",
    book_slug: parsed.bookSlug,
    chapter: parsed.chapter,
    start_verse: Number.isFinite(start) ? start : undefined,
    end_verse: Number.isFinite(end) ? end : undefined,
    version: "KJV",
  };
}

export function discoverPassages(
  query: string,
  topics: string[] = [],
  limit = 3,
): ScripturePassage[] {
  const trimmed = query.trim().toLowerCase();
  let results = catalog.passages as Array<{
    id: string;
    text: string;
    reference: string;
    source: string;
    topics: string[];
  }>;

  if (trimmed) {
    results = results.filter((p) =>
      p.text.toLowerCase().includes(trimmed)
      || p.reference.toLowerCase().includes(trimmed)
      || p.topics.some((t) => t.includes(trimmed) || trimmed.includes(t))
    );
  }

  if (topics.length) {
    const topicSet = new Set(topics.map((t) => t.toLowerCase()));
    results = results.filter((p) => p.topics.some((t) => topicSet.has(t)));
  }

  return results
    .filter((p) => p.source === "scripture")
    .slice(0, limit)
    .map((p) => ({
      reference: p.reference,
      text: p.text,
      source: "curated_catalog" as const,
      catalog_passage_id: p.id,
    }));
}

export async function executeScriptureTool(
  name: string,
  args: Record<string, unknown>,
): Promise<{ passages: ScripturePassage[] }> {
  if (name === "lookup_passage") {
    const reference = String(args.reference ?? "");
    const passage = await lookupPassage(reference);
    return { passages: passage ? [passage] : [] };
  }

  if (name === "discover_passages") {
    const query = String(args.query ?? "");
    const topics = Array.isArray(args.topics)
      ? args.topics.map(String)
      : [];
    const limit = typeof args.limit === "number" ? args.limit : 3;
    return { passages: discoverPassages(query, topics, limit) };
  }

  return { passages: [] };
}

/** Skip tool lookup when client already prefetched the same reference. */
export function prefetchedCoversLookup(
  prefetched: ScripturePassage[] | undefined,
  reference: string,
): boolean {
  if (!prefetched?.length) return false;
  const parsed = parseBibleReference(reference);
  if (!parsed) return false;
  return prefetched.some(
    (p) => p.reference.toLowerCase() === parsed.displayReference.toLowerCase(),
  );
}
