-- Prayer wall, daily rhythm, morning profile sync extensions

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS morning_profile jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS public.prayer_wall_notes (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('request', 'reminder', 'answered')),
  text text NOT NULL,
  focus_tag text,
  rotation double precision NOT NULL DEFAULT 0,
  tint_index int NOT NULL DEFAULT 0,
  answered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.prayer_wall_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prayer_wall_notes_all_own" ON public.prayer_wall_notes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_prayer_wall_notes_user_created
  ON public.prayer_wall_notes(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.daily_rhythm_completions (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  completion_date date NOT NULL,
  ring_kind text NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, completion_date, ring_kind)
);

ALTER TABLE public.daily_rhythm_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "daily_rhythm_completions_all_own" ON public.daily_rhythm_completions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_daily_rhythm_user_date
  ON public.daily_rhythm_completions(user_id, completion_date DESC);
