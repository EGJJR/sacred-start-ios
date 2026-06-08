import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CompletionRow {
  completed_date: string;
  mood: string | null;
  summary: Record<string, unknown> | null;
}

interface JourneyRow {
  kind: string;
  title: string;
  body: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

const moodEmoji: Record<string, string> = {
  peaceful: "🍃",
  overwhelmed: "🌧️",
  grateful: "😊",
  restless: "💨",
  hopeful: "🌅",
};

function weekBounds(now = new Date()) {
  const day = now.getDay();
  const start = new Date(now);
  start.setDate(now.getDate() - day);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  return {
    start: start.toISOString().slice(0, 10),
    end: end.toISOString().slice(0, 10),
  };
}

function weekFlags(completions: Set<string>, now = new Date()): boolean[] {
  const day = now.getDay();
  const start = new Date(now);
  start.setDate(now.getDate() - day);
  start.setHours(0, 0, 0, 0);
  return Array.from({ length: 7 }, (_, offset) => {
    const d = new Date(start);
    d.setDate(start.getDate() + offset);
    return completions.has(d.toISOString().slice(0, 10));
  });
}

function computeStreak(dates: string[]): number {
  if (!dates.length) return 0;
  const sorted = [...new Set(dates)].sort().reverse();
  let streak = 0;
  let cursor = new Date();
  cursor.setHours(0, 0, 0, 0);

  const todayKey = cursor.toISOString().slice(0, 10);
  const yesterday = new Date(cursor);
  yesterday.setDate(cursor.getDate() - 1);
  const yesterdayKey = yesterday.toISOString().slice(0, 10);

  if (!sorted.includes(todayKey)) {
    if (!sorted.includes(yesterdayKey)) return 0;
    cursor = yesterday;
  }

  while (sorted.includes(cursor.toISOString().slice(0, 10))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function topMood(completions: CompletionRow[]): { mood: string; emoji: string } {
  const counts: Record<string, number> = {};
  for (const row of completions) {
    const mood = (row.mood ?? "peaceful").toLowerCase();
    counts[mood] = (counts[mood] ?? 0) + 1;
  }
  const top = Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "peaceful";
  const label = top.charAt(0).toUpperCase() + top.slice(1);
  return { mood: label, emoji: moodEmoji[top] ?? "🙏" };
}

function summarizeThemes(entries: JourneyRow[]): string[] {
  const themes: Record<string, number> = {};
  const keywords: Record<string, string[]> = {
    family: ["family", "kids", "parent", "marriage", "home"],
    work: ["work", "job", "career", "meeting"],
    anxiety: ["anxious", "worry", "stress", "overwhelm", "fear"],
    gratitude: ["grateful", "thankful", "blessed"],
    rest: ["rest", "tired", "weary", "sleep"],
    faith: ["faith", "trust", "prayer", "god"],
  };

  for (const entry of entries) {
    const text = `${entry.title} ${entry.body ?? ""}`.toLowerCase();
    for (const [theme, words] of Object.entries(keywords)) {
      if (words.some((word) => text.includes(word))) {
        themes[theme] = (themes[theme] ?? 0) + 1;
      }
    }
  }

  return Object.entries(themes)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([theme]) => theme);
}

async function generatePastoralCopy(
  apiKey: string,
  stats: Record<string, unknown>,
): Promise<{ headline: string; body: string; weeklyNarrative: string }> {
  const res = await fetch("https://api.deepseek.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      max_tokens: 640,
      temperature: 0.7,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            'You are a gentle pastoral companion in a Christian morning devotion app. Write warm, concise encouragement — never preachy, never invent Bible verses. Respond with JSON only: {"headline": "short title", "body": "2-3 sentences for the user", "weekly_narrative": "three short paragraphs separated by blank lines telling the story of their week spiritually"}',
        },
        {
          role: "user",
          content: `Weekly devotion stats and journal themes:\n${JSON.stringify(stats, null, 2)}`,
        },
      ],
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(err);
  }

  const data = await res.json();
  const content = data.choices?.[0]?.message?.content ?? "{}";
  const parsed = JSON.parse(content);
  return {
    headline: parsed.headline ?? "A word for you",
    body: parsed.body ??
      "Keep showing up — your sanctuary is waiting each morning.",
    weeklyNarrative: parsed.weekly_narrative ??
      parsed.weeklyNarrative ??
      "This week you kept returning to quiet moments before the day began.\n\nEven when life felt full, you made space to notice what mattered.\n\nThat rhythm of showing up is its own kind of faithfulness.",
  };
}

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

    const body = await req.json().catch(() => ({}));
    const period = body.period ?? "weekly";
    const { start, end } = weekBounds();

    const { data: weekRows, error: weekError } = await supabase
      .from("devotion_completions")
      .select("completed_date, mood, summary")
      .gte("completed_date", start)
      .lte("completed_date", end);
    if (weekError) throw weekError;

    const { data: allRows, error: allError } = await supabase
      .from("devotion_completions")
      .select("completed_date, mood")
      .order("completed_date", { ascending: false });
    if (allError) throw allError;

    const { data: journeyRows, error: journeyError } = await supabase
      .from("journey_entries")
      .select("kind, title, body, metadata, created_at")
      .gte("created_at", `${start}T00:00:00.000Z`)
      .lte("created_at", `${end}T23:59:59.999Z`)
      .order("created_at", { ascending: false })
      .limit(40);
    if (journeyError) throw journeyError;

    const weekCompletions = (weekRows ?? []) as CompletionRow[];
    const allCompletions = (allRows ?? []) as CompletionRow[];
    const journeyEntries = (journeyRows ?? []) as JourneyRow[];
    const allDates = allCompletions.map((r) => r.completed_date);
    const weekDateSet = new Set(weekCompletions.map((r) => r.completed_date));
    const flags = weekFlags(weekDateSet);
    const top = topMood(weekCompletions.length ? weekCompletions : allCompletions);
    const themes = summarizeThemes(journeyEntries);

    const statsPayload = {
      period,
      mornings_this_week: flags.filter(Boolean).length,
      top_mood: top.mood,
      top_mood_emoji: top.emoji,
      current_streak: computeStreak(allDates),
      total_days: allDates.length,
      week_completed: flags,
      journey_highlights: journeyEntries.slice(0, 8).map((entry) => ({
        kind: entry.kind,
        title: entry.title,
        preview: (entry.body ?? "").slice(0, 120),
      })),
      recurring_themes: themes,
    };

    const { data: cached } = await supabase
      .from("ai_insights")
      .select("headline, body, stats, created_at")
      .eq("insight_type", "weekly")
      .eq("period_start", start)
      .eq("period_end", end)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    let headline = cached?.headline ?? "A word for you";
    let highlightInsight = cached?.body ??
      "Keep showing up — your sanctuary is waiting each morning.";
    let weeklyNarrative =
      (cached?.stats as Record<string, unknown> | null)?.weekly_narrative as string | undefined ??
      "This week you kept returning to quiet moments before the day began.\n\nEven when life felt full, you made space to notice what mattered.\n\nThat rhythm of showing up is its own kind of faithfulness.";

    const cacheAge = cached?.created_at
      ? Date.now() - new Date(cached.created_at).getTime()
      : Infinity;
    const shouldRegenerate = !cached || cacheAge > 6 * 60 * 60 * 1000;

    if (shouldRegenerate) {
      const generated = await generatePastoralCopy(deepseekKey, statsPayload);
      headline = generated.headline;
      highlightInsight = generated.body;
      weeklyNarrative = generated.weeklyNarrative;

      await supabase.from("ai_insights").insert({
        user_id: user.id,
        period_start: start,
        period_end: end,
        insight_type: "weekly",
        headline,
        body: highlightInsight,
        stats: { ...statsPayload, weekly_narrative: weeklyNarrative },
      });
    }

    return new Response(
      JSON.stringify({
        ...statsPayload,
        headline,
        highlight_insight: highlightInsight,
        weekly_narrative: weeklyNarrative,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
