# Sacred Start — Changelog

Product and design changes for the iOS app (Xcode target: **DevotionLock**; marketing name: **Sacred Start**).  
Code remains the source of truth; this log explains what shipped and why it matters.

---

## Unreleased

Work in progress on `develop` since v1.1 (2026-06-24). Not yet tagged or on TestFlight.

### Design & UI

- **Flat tab wash vs sanctuary gradient** — Home, Chaplain, and Profile browse on a near-flat `ABYFlatTabWashBackground` so white cards and neutral ink stay primary. The Journal tab alone keeps the immersive `ABYCleanGradientBackground` wash, cross-fading when the user switches tabs (`MainTabShellBackground` in `MainTabView.swift`).
- **Neutral glass navigation** — Bottom bar regrouped into two glass pills flanking the Sacred Orb (`BottomNavigationBar.swift`, `ABYGlassBarBackground`). Selected tabs get a soft capsule highlight instead of saturated color fills.
- **Sacred Orb as rhythm coach** — Center orb resolves its label, pulse, and destination from daily rhythm state (`SacredOrbState.swift`): morning devotion, journal hub, evening reflection, or Chaplain chat. Progress arc reflects completed rhythm rings.
- **Gemini-style flat chat canvas** — Chaplain conversation uses `ABYChatWashBackground`: a single flat off-white field with no blue edge fades or gradient bands (`ABYChatComponents.swift`). Matches the [Google Gemini empty chat](https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726) reference.
- **Bible reader flat shells** — Scripture library, sanctuary browser, and chapter reader use `ABYBackground(style: .tabShell)` instead of full sanctuary gradients, keeping reading surfaces calm and typographic.
- **Chaplain hub polish** — `AIInsightsView` adopts the same Gemini greeting and suggestion rail as full chat for visual continuity.
- **Design Tour** — Debug tour updated with Morning Wrapped and current chat/journal specimens (`DesignTourView.swift`).
- **In-app release notes scaffold** — `ReleaseNotes.swift` wires Notelet for version 1.1 copy; ready to extend per ship.

### Chaplain / AI Chat

- **Presence and streaming states** — `ChaplainPresenceIndicator` shows distinct modes: reflecting (animated dots), searching Scripture (pulsing book icon + label), and loading a resumed thread (skeleton lines). Replaces a generic spinner and gives users honest feedback during SSE latency (`ChaplainComponents.swift`, `ChaplainChatView.swift`).
- **Markdown stripping** — `ChaplainMessageFormatter` removes bold, headings, horizontal rules, and em-dashes from model output so threads read as plain pastoral prose, not leaked formatting.
- **Centered composer placeholder** — Empty input shows a centered “Ask Chaplain” placeholder that collapses on focus, matching Gemini’s calm empty composer (`GeminiChatInputBar`).
- **Speech-to-text in chat** — Inline dictation on the chat composer via `SpeechTranscriptionService`: mic toggle, live partials, cancel/merge flow, and permission alert. Voice full-screen session remains behind `FeatureFlags.voiceChatEnabled` (currently `false`).
- **Scripture tool loop** — Chaplain can look up and cite verified passages through a server-side tool round-trip. iOS prefetches when `BibleReferenceParser` detects a reference in the user message. Citation cards render in-thread (`ChaplainScriptureComponents.swift`, `ScriptureCorpus.swift`). See [chaplain-scripture-tools.md](system-design/chaplain-scripture-tools.md).
- **Thread resume and context** — Chat hydrates resumed conversations with title, skeleton load state, and scripture attachments on messages. Bible references in replies can open the chapter reader inline.
- **Ephemeral Chaplain mode** — Internal AI tasks (`transcript_polish`, `guided_prayer`) set `context.ephemeral = true`. Edge functions skip persisting those conversations; iOS deletes any leaked conversation IDs after the stream completes.
- **Chat history cleanup** — History list uses flat wash, search, grouped Today/Yesterday sections, swipe-to-delete, and confirmation sheets. Rows show a smart title derived from the first real exchange; mood-based subtitles removed in favor of preview text only when it adds information (`chaplainHistorySubtitle` on `Conversation`).
- **Internal prompt filtering** — `ConversationMerger.isInternalChaplainRequest` hides guided-prayer JSON and transcript-polish threads from Chaplain history.
- **Warmer edge prompt** — `supabase/functions/chaplain-chat/prompt.ts` revised for conversational tone, Bible Q&A guidance, and plain-text replies (no markdown artifacts).

### Journal & Voice

- **Journal hub redesign** — Timeline header with streak pill, “What’s on your mind?” capture card (Write / Devotion / Voice chips), and white ABY timeline cards. Chaplain threads no longer duplicate on the Journal tab (`ConversationMerger.journalTimeline`).
- **Speech polish with user agency** — After dictation, `ABYSpeechPolishReview` offers **Keep as spoken** or **Tidy gently**. Tidy runs on-device organization first (`JournalTranscriptOrganizer`), then optional ephemeral AI formatting for longer reflections when signed in (`TranscriptPolishService`). Blur-reveal animation previews the tidied text before commit.
- **Assisted journal flow** — Rhythm steps and entry views refined for mad-libs, mood sync from intention, and cleaner completion handoff (`JournalRhythmSteps.swift`, `JournalEntryViews.swift`).
- **Unified Guided Entry surface** — `GuidedJournalEntryView` shared by journal hub, Chaplain wisdom prompts, and morning devotion reflect path. Cream `ABYGuidedJournalBackground`, editorial prompt, starter phrases, mic/dictation, Finish CTA ([ABY guided entry](https://mobbin.com/screens/44178cbe-8235-4163-9017-0a2f106727fb)).
- **Morning devotion flow** — Tier-aware choreography (`MorningFlowPlan`): arrive → check-in → pray (threshold prayer) or reflect (Guided Entry) → word reveal → optional depth. Warm sunset onboarding env, step labels, thin progress bar (`MorningFlowView.swift`).
- **Sacred guided prayer** — First-person speakable lines, breath threshold, no blocking weave overlay (`SacredPrayerComponents.swift`, `GuidedPrayerComposer.swift`). Prayers rewritten in catalog for aloud repetition.
- **Conversation detail** — Detail view uses tab-shell background for Chaplain-tagged threads and gradient for devotion captures; mood shown only when substantive.

### Bible / Scripture

- **Scripture corpus module** — Shared lookup/discover logic on iOS and edge (`ScriptureCorpus.swift`, `scripture-corpus.ts`, `tools.ts`). Curated catalog exported via `scripts/export-scripture-catalog.mjs`.
- **Reference parser improvements** — `BibleReferenceParser` handles more natural reference shapes for prefetch and reader deep links.
- **Browse components** — Scripture cards and browse chrome aligned to flat shells and ABY card rhythm (`ScriptureBrowseComponents.swift`).

### Week in Review

- **Story pager recap** — `MorningWrappedView` rebuilt as a horizontal `TabView` story with discrete beats (intro → mornings → rhythm → mood → streak → chaplain → optional AI narrative → closing). Inspired by [How We Feel week stories](https://mobbin.com/screens/f07c9b43-464b-4056-a5c1-80a13ee5002f), [Opal recap](https://mobbin.com/screens/403d27ac-0a46-4cdd-9e8e-a7521bbc8aee), and [Apple Music Replay](https://mobbin.com/screens/a9ad905f-120e-4ead-b895-8f1d63fb40ad). Segment chrome, haptics on page change, and optional weekly narrative from `InsightService`.
- **Entry points** — Home rhythm row, Profile settings (“Your week in review”), and `openMorningWrapped` environment action.

### Navigation

- **FAB → Chaplain** — Center Sacred Orb opens Chaplain chat (sparkles) instead of guided devotion by default; devotion remains available from Home and the orb’s rhythm-aware routing.
- **Prayer wall on Home** — `ChaplainPrayerWallSection` surfaces community prayer preview without leaving Home.
- **Coordinator actions** — `MainTabCoordinator` gains resume chat, assisted journal, morning wrapped, and sacred-orb routing helpers.
- **Paywall guards** — Premium-gated flows (Chaplain, journal hub, guided devotion) share `PaywallAccess.guardPremium` at environment injection sites.

### Backend / Edge functions

- **Chaplain chat SSE expansion** — `chaplain-chat/index.ts` streams `token`, `scripture_search`, `scripture_result`, and `done` events; up to two tool rounds per message; ephemeral flag skips DB writes.
- **Shared scripture corpus** — `_shared/scripture-corpus.ts` and `_shared/bible-reference-parser.ts` mirror iOS parsing for edge tool execution.
- **Prayer circle RLS** — Migrations `20260624150000_fix_circle_memberships_rls.sql` and `20260624160000_circle_delete_leave_rls.sql` fix recursive policy errors and add leave/delete rules.
- **Sync coordinator** — Improved merge and preference sync for circles and journey data (`SyncCoordinator.swift`).

### Bug fixes

- **Prayer circle invites** — Membership RLS recursion (Postgres `42P17`) resolved with `user_circle_ids()` security-definer helper.
- **Circle leave/delete** — Users can leave or delete circles they own without policy failures.
- **Chat keyboard layout** — Composer and suggestion chips repositioned to avoid keyboard overlap; auto-focus on open removed.
- **Voice screen flash** — `presentationBackground` on full-screen voice cover prevents black flash before gradient mounts.
- **Streak screen readability** — Streak hero moved to light ABY card on soft gradient (no dark mesh + light text clash).

---

## [1.1] — 2026-06-24

**Sacred Start** branding and ABY-informed UX overhaul for TestFlight.

### Design & UI

- Unified typography on **Inter Tight** (UI) and **Instrument Serif** (editorial moments).
- New `ABYDesign` token system: spacing, radii, sanctuary gradients, glass surfaces, mood pills.
- Home simplified — devotion CTA and intention card above the fold; less scrolling to begin.
- Journal tab redesigned with ABY timeline, week strip, and capture chips.
- Settings and profile aligned to [ABY Journal settings](https://mobbin.com/screens/121ba456-3b84-44f9-87b0-71f03ecfde6f).
- Sacred Heart brand mark and holy card asset for devotional moments.
- Clean gradient (`ABYCleanGradientBackground`) for voice, loading, and journal immersive flows.

### Chaplain / AI Chat

- Dedicated chat components (`ABYChatComponents.swift`) with suggestion chips and conversation history entry.
- Chaplain tab rebuilt: hero card, prompt chips, today’s devotion exchange, reflection teaser.
- Streaming replies via Supabase edge function and DeepSeek.

### Journal & Voice

- Guided journal flow: mood → mad-libs → scripture → voice → celebration ([ABY mad-libs refs](https://mobbin.com/screens/5c0e4735-be8c-426b-9e69-83c2c7ca148e)).
- Streak screen with calendar, stats, and 7-day challenge ([ABY streak](https://mobbin.com/screens/49fcbbc9-a0d3-4a10-88a9-a791c3c8f1a6)).
- `StreakManager` with demo seed data and week completion flags on Home.

### Navigation

- Flame badge opens streak sheet from Home and Journal headers.
- Profile header streak tappable.

### Backend / Bug fixes

- Prayer circle invite codes more reliable.
- Onboarding notification copy and auth flow polish.
- Email confirm disabled for immediate sign-up (documented in `supabase/README.md`).

---

## [1.0] — 2026-06-10

Initial TestFlight-ready build.

### Product

- Mobbin-inspired paywall with weekly, monthly, and annual subscriptions (`DevotionProducts.swift`).
- Streak identity milestones and circle challenges for retention.
- Hybrid Bible reader: curated passages offline + KJV lookup via [wldeh/bible-api](https://github.com/wldeh/bible-api) CDN (`FeatureFlags.bibleReaderEnabled`).
- Verse highlights and chapter browse.

### Backend

- Supabase schema: profiles, conversations, devotion sessions, journey entries, prayer circles.
- `chaplain-chat` edge function with DeepSeek.
- CI: GitHub Actions iOS simulator build on `develop` and `main`.

### Infrastructure

- `develop` / `main` branching model documented.
- Release entitlements without Family Controls for TestFlight upload until distribution approval.

---

## [0.1] — 2026-06-08

- Initial repository: Sacred Start iOS app (`DevotionLock` target), widget extension scaffold, Supabase migrations, Xcode project.

---

## How to update this log

1. Add unreleased bullets under **Unreleased** during development.
2. On ship, rename **Unreleased** to `[x.y] — YYYY-MM-DD`, bump `CFBundleShortVersionString`, and extend `ReleaseNotes.swift` for Notelet.
3. Link Mobbin refs from Swift file headers when a screen cites external inspiration.
4. Cross-link system decisions in [system-design/](system-design/).
