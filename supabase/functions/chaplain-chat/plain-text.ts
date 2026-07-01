/**
 * Strip Markdown / emphasis the model may emit in Chaplain replies.
 * Keep in sync with iOS ChaplainMessageFormatter.
 */
export function sanitizeChaplainReply(raw: string): string {
  let text = raw.replace(/\r\n/g, "\n");

  text = text.replace(/\*\*\*/g, "");
  text = text.replace(/\*\*/g, "");
  text = text.replace(/__/g, "");
  text = text.replace(/\*([^*\n]+)\*/g, "$1");
  text = text.replace(/_([^_\n]+)_/g, "$1");

  text = text.replace(/\n[ \t]*[-*_]{3,}[ \t]*\n/g, "\n\n");
  text = text.replace(/^[ \t]*[-*_]{3,}[ \t]*$/gm, "");
  text = text.replace(/^#{1,6}\s+/gm, "");
  text = text.replace(/^[ \t]*[-*+]\s+/gm, "• ");
  text = text.replace(/—/g, ", ");
  text = text.replace(/–/g, ", ");
  text = text.replace(/\n{3,}/g, "\n\n");
  text = text.replace(/\*/g, "");

  return text.trim();
}
