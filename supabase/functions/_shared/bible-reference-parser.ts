/**
 * Bible reference parser — mirrors iOS BibleReferenceParser.swift
 */

export interface ParsedBibleReference {
  bookSlug: string;
  bookName: string;
  chapter: number;
  verse?: number;
  endVerse?: number;
  displayReference: string;
}

const ALIASES: Record<string, string> = {
  ps: "psalms",
  psa: "psalms",
  psalm: "psalms",
  psalms: "psalms",
  jn: "john",
  jhn: "john",
  john: "john",
  rom: "romans",
  romans: "romans",
  phil: "philippians",
  philippians: "philippians",
  "1 cor": "1corinthians",
  "1cor": "1corinthians",
  "1 corinthians": "1corinthians",
  "1corinthians": "1corinthians",
  matt: "matthew",
  matthew: "matthew",
  prov: "proverbs",
  proverbs: "proverbs",
  isa: "isaiah",
  isaiah: "isaiah",
  jer: "jeremiah",
  jeremiah: "jeremiah",
  gen: "genesis",
  genesis: "genesis",
};

const BOOK_NAMES: Record<string, string> = {
  genesis: "Genesis",
  exodus: "Exodus",
  psalms: "Psalms",
  proverbs: "Proverbs",
  matthew: "Matthew",
  john: "John",
  romans: "Romans",
  philippians: "Philippians",
  "1corinthians": "1 Corinthians",
  "2corinthians": "2 Corinthians",
  isaiah: "Isaiah",
  jeremiah: "Jeremiah",
  lamentations: "Lamentations",
  hebrews: "Hebrews",
  james: "James",
  revelation: "Revelation",
};

export function resolveBookSlug(rawName: string): string | null {
  const key = rawName
    .toLowerCase()
    .replace(/\./g, "")
    .replace(/\s+/g, " ")
    .trim();
  const compact = key.replace(/\s/g, "");
  if (BOOK_NAMES[compact]) return compact;
  if (ALIASES[key]) return ALIASES[key];
  if (ALIASES[compact]) return ALIASES[compact];
  if (BOOK_NAMES[key.replace(/\s/g, "")]) return key.replace(/\s/g, "");
  return null;
}

export function parseBibleReference(input: string): ParsedBibleReference | null {
  const trimmed = input.trim();
  if (!trimmed || !/\d/.test(trimmed)) return null;

  const pattern =
    /^(?:(\d)\s+)?([A-Za-z][A-Za-z.\s]*?)\s+(\d{1,3})(?::(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?$/;
  const match = trimmed.match(pattern);
  if (!match) return null;

  let bookPart = match[2]?.trim() ?? "";
  if (match[1]) bookPart = `${match[1]} ${bookPart}`;
  const chapter = Number(match[3]);
  const verse = match[4] ? Number(match[4]) : undefined;
  const endVerse = match[5] ? Number(match[5]) : undefined;

  const slug = resolveBookSlug(bookPart);
  if (!slug || !chapter) return null;

  const bookName = BOOK_NAMES[slug] ?? bookPart;
  let displayReference = `${bookName} ${chapter}`;
  if (verse) {
    displayReference += endVerse && endVerse !== verse
      ? `:${verse}-${endVerse}`
      : `:${verse}`;
  }

  return { bookSlug: slug, bookName, chapter, verse, endVerse, displayReference };
}

export function looksLikeReference(input: string): boolean {
  return parseBibleReference(input) !== null;
}

/** Finds an embedded reference like "John 3:16" inside natural language. */
export function extractBibleReference(input: string): ParsedBibleReference | null {
  const trimmed = input.trim();
  if (!trimmed || !/\d/.test(trimmed)) return null;

  const pattern =
    /(?:(\d)\s+)?([A-Za-z][A-Za-z.\s]*?)\s+(\d{1,3})(?::(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?/g;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(trimmed)) !== null) {
    let bookPart = match[2]?.trim() ?? "";
    if (match[1]) bookPart = `${match[1]} ${bookPart}`;
    const chapter = Number(match[3]);
    const verse = match[4] ? Number(match[4]) : undefined;
    const endVerse = match[5] ? Number(match[5]) : undefined;

    const slug = resolveBookSlug(bookPart);
    if (!slug || !chapter) continue;

    const bookName = BOOK_NAMES[slug] ?? bookPart;
    let displayReference = `${bookName} ${chapter}`;
    if (verse) {
      displayReference += endVerse && endVerse !== verse
        ? `:${verse}-${endVerse}`
        : `:${verse}`;
    }

    return { bookSlug: slug, bookName, chapter, verse, endVerse, displayReference };
  }

  return null;
}
