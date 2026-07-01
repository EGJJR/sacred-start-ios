import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  buildChaplainSystemPrompt,
  type ChaplainContext,
  type ScripturePassagePayload,
} from "./prompt.ts";
import { sanitizeChaplainReply } from "./plain-text.ts";
import { MAX_TOOL_ROUNDS, SCRIPTURE_TOOLS } from "./tools.ts";
import {
  executeScriptureTool,
  normalizeScriptureText,
  prefetchedCoversLookup,
  type ScripturePassage,
} from "../_shared/scripture-corpus.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ChatMessage = Record<string, unknown>;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const conversationId: string | null = body.conversation_id ?? null;
    const messages: Array<{ role: string; content: string }> = body.messages ?? [];
    const context: ChaplainContext | undefined = body.context;
    const ephemeral =
      context?.ephemeral === true ||
      context?.intent === "guided_prayer" ||
      context?.intent === "transcript_polish";

    if (!messages.length) {
      return new Response(JSON.stringify({ error: "No messages provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const deepseekKey = Deno.env.get("DEEPSEEK_API_KEY");
    if (!deepseekKey) {
      return new Response(
        JSON.stringify({
          error: "AI not configured. Set DEEPSEEK_API_KEY in Edge Function secrets.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    let convId = conversationId;
    if (!convId && !ephemeral) {
      const { data: conv, error: convError } = await supabase
        .from("conversations")
        .insert({
          user_id: user.id,
          title: context?.mood ? `Morning — ${context.mood}` : "Chaplain Chat",
          mood: context?.mood ?? null,
        })
        .select("id")
        .single();
      if (convError) throw convError;
      convId = conv.id;
    }

    const lastUserMsg = messages[messages.length - 1];
    if (!ephemeral && convId && lastUserMsg?.role === "user") {
      await supabase.from("messages").insert({
        conversation_id: convId,
        user_id: user.id,
        role: "user",
        content: lastUserMsg.content,
      });
    }

    const encoder = new TextEncoder();
    const decoder = new TextDecoder();

    const stream = new ReadableStream({
      async start(controller) {
        const emit = (payload: Record<string, unknown>) => {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify(payload)}\n\n`),
          );
        };

        if (convId) {
          emit({ type: "conversation_id", conversation_id: convId });
        }

        const prefetched: ScripturePassage[] = (context?.prefetched_scripture ?? [])
          .map(normalizePassage)
          .filter(Boolean) as ScripturePassage[];

        if (prefetched.length) {
          emit({ type: "scripture_result", passages: prefetched });
        }

        let chatMessages: ChatMessage[] = [
          { role: "system", content: buildChaplainSystemPrompt(context) },
          ...messages.map((m) => ({
            role: m.role === "chaplain" ? "assistant" : "user",
            content: m.content,
          })),
        ];

        const collectedPassages: ScripturePassage[] = [...prefetched];
        let toolRounds = 0;

        while (toolRounds < MAX_TOOL_ROUNDS) {
          const llmRes = await fetch("https://api.deepseek.com/v1/chat/completions", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${deepseekKey}`,
            },
            body: JSON.stringify({
              model: "deepseek-chat",
              max_tokens: 1024,
              stream: false,
              messages: chatMessages,
              tools: SCRIPTURE_TOOLS,
            }),
          });

          if (!llmRes.ok) {
            const errText = await llmRes.text();
            emit({ type: "error", message: errText });
            controller.close();
            return;
          }

          const completion = await llmRes.json();
          const choice = completion.choices?.[0];
          const assistantMessage = choice?.message;

          if (!assistantMessage) break;

          const toolCalls = assistantMessage.tool_calls as Array<{
            id: string;
            type: string;
            function: { name: string; arguments: string };
          }> | undefined;

          if (!toolCalls?.length) {
            if (assistantMessage.content) {
              const cleaned = sanitizeChaplainReply(assistantMessage.content);
              emit({ type: "token", text: cleaned });
              if (!ephemeral && convId) {
                await persistChaplainMessage(supabase, user.id, convId, cleaned);
              }
            }
            emit({ type: "done" });
            controller.close();
            return;
          }

          chatMessages.push(assistantMessage);

          for (const toolCall of toolCalls) {
            const name = toolCall.function.name;
            let args: Record<string, unknown> = {};
            try {
              args = JSON.parse(toolCall.function.arguments || "{}");
            } catch {
              args = {};
            }

            if (
              name === "lookup_passage"
              && prefetchedCoversLookup(prefetched, String(args.reference ?? ""))
            ) {
              chatMessages.push({
                role: "tool",
                tool_call_id: toolCall.id,
                content: JSON.stringify({ passages: prefetched }),
              });
              continue;
            }

            emit({
              type: "scripture_search",
              status: "looking",
              reference: name === "lookup_passage" ? args.reference : undefined,
              query: name === "discover_passages" ? args.query : undefined,
            });

            const result = await executeScriptureTool(name, args);
            const newPassages = result.passages.filter(
              (p) => !collectedPassages.some(
                (existing) => passageDedupeKey(existing) === passageDedupeKey(p),
              ),
            );

            if (newPassages.length) {
              collectedPassages.push(...newPassages);
              emit({ type: "scripture_result", passages: newPassages });
            }

            chatMessages.push({
              role: "tool",
              tool_call_id: toolCall.id,
              content: JSON.stringify(result),
            });
          }

          toolRounds += 1;
        }

        // Stream final pastoral reply after tool rounds
        const streamRes = await fetch("https://api.deepseek.com/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${deepseekKey}`,
          },
          body: JSON.stringify({
            model: "deepseek-chat",
            max_tokens: 1024,
            stream: true,
            messages: chatMessages,
          }),
        });

        if (!streamRes.ok) {
          const errText = await streamRes.text();
          emit({ type: "error", message: errText });
          controller.close();
          return;
        }

        let fullResponse = "";
        let buffer = "";
        const reader = streamRes.body!.getReader();

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() ?? "";

          for (const line of lines) {
            if (!line.startsWith("data: ")) continue;
            const data = line.slice(6).trim();
            if (!data || data === "[DONE]") continue;
            try {
              const parsed = JSON.parse(data);
              const token = parsed.choices?.[0]?.delta?.content;
              if (token) {
                fullResponse += token;
                emit({ type: "token", text: token });
              }
            } catch {
              // ignore partial JSON
            }
          }
        }

        if (fullResponse.trim() && !ephemeral && convId) {
          await persistChaplainMessage(supabase, user.id, convId, fullResponse.trim());
        }

        emit({ type: "done" });
        controller.close();
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function persistChaplainMessage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  convId: string,
  content: string,
) {
  const cleaned = sanitizeChaplainReply(content);
  const { error: insertError } = await supabase.from("messages").insert({
    conversation_id: convId,
    user_id: userId,
    role: "chaplain",
    content: cleaned,
  });
  if (insertError) {
    console.error("persistChaplainMessage failed:", insertError.message);
    return;
  }
  await supabase.from("conversations").update({
    updated_at: new Date().toISOString(),
  }).eq("id", convId);
}

function passageDedupeKey(passage: ScripturePassage): string {
  return `${passage.reference.toLowerCase()}|${normalizeScriptureText(passage.text)}`;
}

function normalizePassage(payload: ScripturePassagePayload): ScripturePassage | null {
  if (!payload.reference || !payload.text) return null;
  return {
    reference: payload.reference,
    text: normalizeScriptureText(payload.text),
    source: payload.source === "curated_catalog" ? "curated_catalog" : "bible_api",
    book_slug: payload.book_slug,
    chapter: payload.chapter,
    start_verse: payload.start_verse,
    end_verse: payload.end_verse,
    catalog_passage_id: payload.catalog_passage_id,
    version: payload.version,
  };
}
