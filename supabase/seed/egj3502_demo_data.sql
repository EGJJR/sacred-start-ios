-- Demo journal, streak, and Chaplain data for egj3502@gmail.com
--
-- HOW TO RUN (Supabase Dashboard):
--   1. SQL Editor → New query
--   2. Paste THIS ENTIRE FILE (starts with "do $$", ends with "end $$;")
--   3. Click Run
--   Do NOT paste "supabase db push" here — that is a terminal command, not SQL.
--
-- Safe to re-run: clears prior demo rows for this user, then re-seeds.

do $$
declare
  uid uuid;
  d date;
  i int;
  mood text;
  mood_emoji text;
  session_id uuid;
  conv_id uuid;
  verse_ref text;
  journal_preview text;
  insight_text text;
  summary_json jsonb;
  week_start date;
  week_end date;
begin
  select id into uid from auth.users where lower(email) = lower('egj3502@gmail.com');
  if uid is null then
    raise exception 'No auth user found for egj3502@gmail.com — sign up in the app first.';
  end if;

  insert into public.profiles (id)
  values (uid)
  on conflict (id) do nothing;

  -- Clear existing synced content for a clean re-seed
  delete from public.messages
  where conversation_id in (select id from public.conversations where user_id = uid);

  delete from public.conversations where user_id = uid;
  delete from public.journey_entries where user_id = uid;
  delete from public.devotion_completions where user_id = uid;
  delete from public.devotion_sessions where user_id = uid;
  delete from public.ai_insights where user_id = uid;

  -- 21-day streak ending today (skip 1 day 10 days ago for a realistic gap? user asked for streaks - use continuous 21 days)
  for i in 0..20 loop
    d := current_date - i;

    mood := (array[
      'Peaceful', 'Grateful', 'Hopeful', 'Peaceful', 'Grateful',
      'Overwhelmed', 'Hopeful', 'Peaceful', 'Grateful', 'Restless',
      'Peaceful', 'Grateful', 'Hopeful', 'Peaceful', 'Grateful',
      'Hopeful', 'Peaceful', 'Grateful', 'Peaceful', 'Hopeful', 'Grateful'
    ])[i + 1];

    mood_emoji := case lower(mood)
      when 'peaceful' then '🍃'
      when 'grateful' then '😊'
      when 'hopeful' then '🌅'
      when 'overwhelmed' then '🌧️'
      when 'restless' then '💨'
      else '🙏'
    end;

    verse_ref := (array[
      'Lamentations 3:22-23', 'Psalm 46:10', 'Isaiah 40:31', 'Matthew 11:28', 'Philippians 4:6-7',
      'Psalm 23:1-3', 'Romans 15:13', 'Psalm 119:105', 'James 1:5', 'Hebrews 4:16',
      'Psalm 16:11', 'Colossians 3:15', 'Micah 6:8', 'Psalm 37:7', '2 Corinthians 12:9',
      'Proverbs 3:5-6', 'Psalm 34:18', 'John 14:27', 'Psalm 90:14', 'Isaiah 26:3', 'Psalm 143:8'
    ])[i + 1];

    journal_preview := (array[
      'Quiet heart before emails · trusting God with the week ahead',
      'Thankful for morning light · family health · a second chance today',
      'Waiting on renewed strength · choosing hope over hurry',
      'Be still and know — phone stayed off until devotion finished',
      'Named anxiety, released it in prayer · peace before meetings',
      'Heavy morning, lighter after journaling · God met me in the stillness',
      'Hopeful about a new project · asked for wisdom and courage',
      'Slow breaths, open Bible, unhurried start',
      'Grateful for answered prayer about reconciliation',
      'Restless energy channeled into intention · one thing at a time',
      'Joy in ordinary routines · coffee, scripture, silence',
      'Letting Christ rule my heart today · less scrolling, more presence',
      'Justice, mercy, humility — carrying that into work',
      'Wait patiently — release control of outcomes',
      'Weakness acknowledged · grace sufficient for today',
      'Trust over understanding · major decision ahead',
      'God close to the brokenhearted · naming grief honestly',
      'Peace not as the world gives · anchoring before noise',
      'Satisfy us in the morning · hungry for presence',
      'Perfect peace for minds stayed on Him',
      'Morning mercy · new mercies, new beginning'
    ])[i + 1];

    insight_text := (array[
      'A peaceful morning with trust in view — you showed up before the rush.',
      'Gratitude is shaping your rhythm — three gifts named, heart softened.',
      'Hopeful energy today; waiting on the Lord is its own kind of strength.',
      'Stillness before noise — your sanctuary practice is deepening.',
      'You brought anxiety to prayer instead of carrying it alone.',
      'Even overwhelmed mornings can become meeting places with God.',
      'Hope and wisdom requested — a mature way to begin hard things.',
      'Unhurried presence — your streak reflects consistency, not perfection.',
      'Grateful for reconciliation — joy is allowed in the journal too.',
      'Restless, but honest — naming it is already a form of peace.',
      'Ordinary gifts noticed — that is spiritual attention.',
      'Peace of Christ as filter — a strong intention for the day.',
      'Micah’s triad as compass — beautiful morning framing.',
      'Patience chosen over control — trust growing quietly.',
      'Grace in weakness — one of the deepest devotion themes.',
      'Trust before clarity — faithfulness in uncertainty.',
      'Honest grief held gently — God can handle the full truth.',
      'Peace received, not manufactured — good foundation for today.',
      'Hunger for morning mercy — appetite for God is a gift.',
      'Mind stayed on Him — peace follows orientation.',
      'Mercy remembered — twenty-one mornings of showing up.'
    ])[i + 1];

    summary_json := jsonb_build_object(
      'insight', insight_text,
      'journal_preview', journal_preview,
      'verse_reference', verse_ref,
      'focus_tags', jsonb_build_array(
        (array['Trust', 'Rest', 'Gratitude', 'Peace', 'Wisdom'])[1 + (i % 5)],
        (array['Family', 'Work', 'Health', 'Guidance', 'Courage'])[1 + ((i + 2) % 5)]
      ),
      'affirmation', (array[
        'I begin in peace.',
        'I receive today as gift.',
        'My strength is renewed.',
        'I am held in stillness.',
        'I cast my cares on Him.',
        'I am not alone in this.',
        'I walk in hope.',
        'I am unhurried in love.',
        'Joy is welcome here.',
        'I channel restlessness into purpose.',
        'I notice grace in small things.',
        'Christ rules my heart today.',
        'I act with mercy and humility.',
        'I wait with trust.',
        'Grace covers my weakness.',
        'I trust the path I cannot see.',
        'God is near to my heart.',
        'I receive His peace.',
        'I am satisfied in His presence.',
        'My mind rests in Him.',
        'Morning mercy is mine.'
      ])[i + 1],
      'saved_verse_phrase', (array[
        'Great is thy faithfulness',
        'Be still, and know',
        'They shall mount up with wings',
        'Come unto me, all ye that labour',
        'The peace of God… shall keep your hearts',
        'He leadeth me beside still waters',
        'The God of hope fill you with all joy and peace',
        'Thy word is a lamp unto my feet',
        'If any of you lack wisdom',
        'Come boldly unto the throne of grace',
        'In thy presence is fulness of joy',
        'Let the peace of Christ rule',
        'Do justly, love mercy, walk humbly',
        'Rest in the Lord, and wait patiently for him',
        'My grace is sufficient for thee',
        'Trust in the Lord with all thine heart',
        'The Lord is nigh unto them that are of a broken heart',
        'Peace I leave with you',
        'O satisfy us early with thy mercy',
        'Thou wilt keep him in perfect peace',
        'Cause me to hear thy lovingkindness in the morning'
      ])[i + 1],
      'voice_transcript', journal_preview,
      'time_label', to_char(d, 'Mon DD') || ' · 7:' || lpad((10 + (i % 40))::text, 2, '0') || ' AM'
    );

    insert into public.devotion_sessions (
      user_id, session_date, mood, emotion, reason, on_mind, plans,
      gratitude, affirmation, saved_verse_phrase, verse_reference, focus_tags
    ) values (
      uid,
      d,
      mood,
      lower(mood),
      case when mood = 'Overwhelmed' then 'too much on the calendar' else 'starting the day intentionally' end,
      (array[
        'work pressure', 'family gratitude', 'future hopes', 'need for rest', 'anxiety about meetings',
        'heavy heart', 'new opportunities', 'desire for slowness', 'reconciliation', 'scattered focus',
        'simple joys', 'inner peace', 'justice at work', 'waiting on God', 'physical tiredness',
        'big decision', 'grief', 'conflict at home', 'spiritual hunger', 'mind racing', 'fresh start'
      ])[i + 1],
      (array[
        'one focused work block', 'call mom', 'walk outside', 'protect morning quiet', 'pray before Slack',
        'ask for help', 'draft proposal', 'no phone until 8am', 'send encouragement', 'single-task afternoon',
        'savor breakfast', 'pause before reacting', 'listen well in meeting', 'journal again tonight', 'early bedtime',
        'seek counsel', 'light a candle and pray', 'repair conversation', 'read psalms', 'breath prayer', 'thank someone'
      ])[i + 1],
      jsonb_build_array('Morning quiet', 'Health', 'People I love'),
      summary_json ->> 'affirmation',
      summary_json ->> 'saved_verse_phrase',
      verse_ref,
      array[
        (array['Trust', 'Rest', 'Gratitude', 'Peace', 'Wisdom'])[1 + (i % 5)],
        (array['Family', 'Work', 'Health', 'Guidance', 'Courage'])[1 + ((i + 2) % 5)]
      ]
    )
    on conflict (user_id, session_date) do update set
      mood = excluded.mood,
      emotion = excluded.emotion,
      reason = excluded.reason,
      on_mind = excluded.on_mind,
      plans = excluded.plans,
      gratitude = excluded.gratitude,
      affirmation = excluded.affirmation,
      saved_verse_phrase = excluded.saved_verse_phrase,
      verse_reference = excluded.verse_reference,
      focus_tags = excluded.focus_tags;

    insert into public.devotion_completions (user_id, completed_date, mood, summary)
    values (uid, d, mood, summary_json)
    on conflict (user_id, completed_date) do update set
      mood = excluded.mood,
      summary = excluded.summary;

    insert into public.journey_entries (user_id, kind, title, body, metadata, created_at)
    values
      (
        uid, 'devotion', 'Morning — ' || mood, journal_preview,
        jsonb_build_object('session_date', d::text, 'mood', mood),
        (d + time '07:15:00') at time zone 'America/New_York'
      ),
      (
        uid, 'gratitude', 'Grateful for',
        'Morning quiet · Health · People I love',
        jsonb_build_object('session_date', d::text, 'mood', mood),
        (d + time '07:18:00') at time zone 'America/New_York'
      ),
      (
        uid, 'verse', 'Saved phrase',
        summary_json ->> 'saved_verse_phrase',
        jsonb_build_object('session_date', d::text, 'verse_reference', verse_ref),
        (d + time '07:20:00') at time zone 'America/New_York'
      );

    if i in (2, 6, 11, 15, 19) then
      insert into public.journey_entries (user_id, kind, title, body, metadata, created_at)
      values (
        uid, 'reflection', 'Wisdom reflection',
        insight_text,
        jsonb_build_object('session_date', d::text),
        (d + time '07:25:00') at time zone 'America/New_York'
      );
    end if;
  end loop;

  -- Chaplain conversations (Journal tab)
  for i in 0..9 loop
    d := current_date - (i * 2);
    mood := (array['Peaceful', 'Grateful', 'Hopeful', 'Overwhelmed', 'Peaceful', 'Grateful', 'Hopeful', 'Restless', 'Peaceful', 'Grateful'])[i + 1];
    conv_id := gen_random_uuid();

    insert into public.conversations (id, user_id, title, mood, created_at, updated_at)
    values (
      conv_id,
      uid,
      (array[
        'Carrying Monday quietly',
        'Gratitude after hard news',
        'Hope for a fresh chapter',
        'When the calendar wins',
        'Stillness before the meeting',
        'Thankful for small mercies',
        'Waiting without rushing',
        'Restless heart, gentle start',
        'Peace after honest prayer',
        'Morning mercy remembered'
      ])[i + 1],
      mood,
      (d + time '07:40:00') at time zone 'America/New_York',
      (d + time '07:48:00') at time zone 'America/New_York'
    );

    insert into public.messages (conversation_id, user_id, role, content, created_at) values
      (
        conv_id, uid, 'user',
        (array[
          'I want to start calm today but my mind is already in tomorrow.',
          'Something hard happened yesterday. I am trying to be grateful anyway.',
          'I feel hopeful but also afraid of getting my hopes up.',
          'I overslept and feel behind before the day even starts.',
          'Big presentation today. I need peace more than polish.',
          'Three small things went right yesterday — I want to hold onto that.',
          'I am in a waiting season and it is tiring.',
          'Restless energy — hard to sit still for devotion.',
          'I prayed honestly about something painful. Feeling lighter.',
          'Twenty-one days in a row. Does consistency matter if I still struggle?'
        ])[i + 1],
        (d + time '07:40:00') at time zone 'America/New_York'
      ),
      (
        conv_id, uid, 'chaplain',
        (array[
          'Calm is not the absence of tomorrow — it is bringing tomorrow to God before you carry it. Name one thing you can release for the next hour.',
          'Gratitude after grief is not denial — it is courage. What one mercy can you thank God for without pretending the hurt is gone?',
          'Hope and fear can coexist. Let hope be honest, not loud. What would a gentle first step look like today?',
          'Behind schedule is not behind God’s care. Breathe once, offer the day, and choose one small faithful next step.',
          'Peace before polish — beautiful instinct. Ask for presence in the room, not just performance. Who needs your humanity more than your polish?',
          'Small mercies are still mercies. Write them down — they become anchors on harder mornings.',
          'Waiting seasons train trust muscles. What if today’s assignment is patience, not progress?',
          'Restlessness can be redirected. Try naming what your body needs — movement, food, silence — before you judge the restlessness.',
          'Honest prayer is never wasted. Lightness after truth is often grace, not forgetting. Receive it.',
          'Consistency is not perfection — it is orientation. Twenty-one mornings of turning toward God reshapes you even when struggle remains.'
        ])[i + 1],
        (d + time '07:46:00') at time zone 'America/New_York'
      );
  end loop;

  -- Weekly AI insight (current week)
  week_start := date_trunc('week', current_date)::date;
  week_end := week_start + 6;

  insert into public.ai_insights (
    user_id, period_start, period_end, insight_type, headline, body, stats
  ) values (
    uid,
    week_start,
    week_end,
    'weekly',
    'Steady mornings, softer heart',
    'You have shown up twenty-one days in a row — not perfectly, but faithfully. Gratitude and peace appear most often in your journal; even overwhelmed days became meeting places with God. Keep protecting the first quiet minutes.',
    jsonb_build_object(
      'period', 'weekly',
      'mornings_this_week', 7,
      'top_mood', 'Peaceful',
      'top_mood_emoji', '🍃',
      'current_streak', 21,
      'total_days', 21,
      'week_completed', jsonb_build_array(true, true, true, true, true, true, true)
    )
  );

  raise notice 'Seeded demo data for user % (egj3502@gmail.com): 21 devotion days, 10 conversations, journey entries, 1 weekly insight.', uid;
end $$;
