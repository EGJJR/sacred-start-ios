-- profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  chaplain_voice_id text NOT NULL DEFAULT 'grace',
  intention_mood text NOT NULL DEFAULT 'Peaceful',
  is_premium boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1), 'Morning Seeker'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- devotion sessions
CREATE TABLE IF NOT EXISTS public.devotion_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_date date NOT NULL,
  mood text,
  emotion text,
  reason text,
  on_mind text,
  plans text,
  gratitude jsonb DEFAULT '[]'::jsonb,
  affirmation text,
  saved_verse_phrase text,
  verse_reference text,
  focus_tags text[] DEFAULT '{}',
  completed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, session_date)
);

ALTER TABLE public.devotion_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "devotion_sessions_all_own" ON public.devotion_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- conversations
CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  devotion_session_id uuid REFERENCES public.devotion_sessions(id) ON DELETE SET NULL,
  title text,
  mood text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "conversations_all_own" ON public.conversations FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- messages
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'chaplain')),
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "messages_all_own" ON public.messages FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- journey entries
CREATE TABLE IF NOT EXISTS public.journey_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind text NOT NULL,
  title text NOT NULL,
  body text NOT NULL DEFAULT '',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.journey_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "journey_entries_all_own" ON public.journey_entries FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ai insights
CREATE TABLE IF NOT EXISTS public.ai_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_start date NOT NULL,
  period_end date NOT NULL,
  insight_type text NOT NULL CHECK (insight_type IN ('daily', 'weekly')),
  headline text NOT NULL,
  body text NOT NULL,
  stats jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_insights_all_own" ON public.ai_insights FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- devotion completions
CREATE TABLE IF NOT EXISTS public.devotion_completions (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  completed_date date NOT NULL,
  mood text,
  summary jsonb DEFAULT '{}'::jsonb,
  PRIMARY KEY (user_id, completed_date)
);

ALTER TABLE public.devotion_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "devotion_completions_all_own" ON public.devotion_completions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- indexes
CREATE INDEX IF NOT EXISTS idx_conversations_user_created ON public.conversations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON public.messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_journey_entries_user_created ON public.journey_entries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_devotion_sessions_user_date ON public.devotion_sessions(user_id, session_date DESC);
;
