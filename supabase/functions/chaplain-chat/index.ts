import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  buildChaplainSystemPrompt,
  type ChaplainContext,
} from "./prompt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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
    if (!convId) {
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
    if (lastUserMsg?.role === "user") {
      await supabase.from("messages").insert({
        conversation_id: convId,
        user_id: user.id,
        role: "user",
        content: lastUserMsg.content,
      });
    }

    const chatMessages = [
      { role: "system", content: buildChaplainSystemPrompt(context) },
      ...messages.map((m) => ({
        role: m.role === "chaplain" ? "assistant" : "user",
        content: m.content,
      })),
    ];

    const llmRes = await fetch("https://api.deepseek.com/v1/chat/completions", {
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

    if (!llmRes.ok) {
      const errText = await llmRes.text();
      return new Response(JSON.stringify({ error: errText }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    let fullResponse = "";

    const stream = new ReadableStream({
      async start(controller) {
        controller.enqueue(
          encoder.encode(
            `data: ${JSON.stringify({ type: "conversation_id", conversation_id: convId })}\n\n`,
          ),
        );

        const reader = llmRes.body!.getReader();
        let buffer = "";

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
                controller.enqueue(
                  encoder.encode(
                    `data: ${JSON.stringify({ type: "token", text: token })}\n\n`,
                  ),
                );
              }
            } catch {
              // ignore partial JSON
            }
          }
        }

        if (fullResponse.trim()) {
          await supabase.from("messages").insert({
            conversation_id: convId,
            user_id: user.id,
            role: "chaplain",
            content: fullResponse.trim(),
          });
          await supabase.from("conversations").update({
            updated_at: new Date().toISOString(),
          }).eq("id", convId);
        }

        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify({ type: "done" })}\n\n`),
        );
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
