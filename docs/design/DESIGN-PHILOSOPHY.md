# Sacred Start — Design Philosophy

How we think about interface, motion, and spiritual product tone for the iOS app.  
This document complements the token files (`ABYDesign.swift`, `AppFont.swift`, `AppTheme.swift`) and the [design system overview](design-system/overview.md).

---

## What we are building

Sacred Start is a **morning sanctuary**, not a productivity dashboard. The interface should feel like opening a quiet room: warm light, readable type, one clear next step. Users arrive scattered; we give them a repeatable ritual—devotion, journal, Chaplain, community—without gamified anxiety or clinical chatbot chrome.

Design references are **Mobbin-informed**, not copied. We study how best-in-class apps handle habit loops, chat, and recap stories, then adapt patterns to Christian devotion language and our ABY-derived visual system.

---

## Core principles

### 1. ABY aesthetic — calm, editorial, card-forward

Primary reference: [ABY Journal](https://mobbin.com) (see grep `mobbin.com` across `DevotionLock/` for screen-level links).

- **Neutral ink on soft fields** — Black and near-black primary text on `#F2F2F7`-family washes (`ABY.Color.textPrimary`, `background`).
- **White cards as content units** — Timeline entries, settings groups, streak hero, and chat presence bubbles sit on white surfaces with light shadow and 1px dividers, not heavy borders.
- **Editorial serif moments** — Instrument Serif for screen titles, welcome lines, and sacred emphasis; Inter Tight for everything interactive (`ABY.Font.editorialTitle`, `.body`).
- **Mood as color, not decoration** — Peach, teal, pink, and purple pills encode emotional state ([How We Feel mood cards](https://mobbin.com/screens/da9f1f1a-766f-4746-b45a-20661adb8ef4), [Calm check-in](https://mobbin.com/screens/40ba5ad3-03c7-4b81-ac40-6a2b447233fa)) without emoji clutter in chrome.

### 2. Flat over gradient stacking

We deliberately **limit simultaneous gradients**:

| Surface | Background | Rationale |
|---------|------------|-----------|
| Home, Chaplain, Profile, Bible browse | `ABYFlatTabWashBackground` | Cards and typography stay focal; avoids “purple haze” fatigue |
| Journal tab | `ABYCleanGradientBackground` | Immersive writing mood; one gradient per session |
| Onboarding / paywall | Sunset mesh or night navy | Distinct lifecycle moments; not daily browsing |
| Chat thread | `ABYChatWashBackground` (flat) | [Gemini](https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726) proves flat canvas beats gradient + bubbles |

`ABYBackground.Style` encodes this: `.tabShell` vs `.app` vs `.onboarding`. When adding a screen, pick **one** background tier—do not stack mesh on gradient on glass.

### 3. Glass surfaces, not glass everything

Glass appears where it **separates navigation from content**:

- Bottom nav pills (`ABYGlassBarBackground`)
- Floating composers and action bars
- Onboarding floating cards over sanctuary mesh

Glass is **neutral** (native Liquid Glass + hairline stroke), not saturated brand glass. Since the app targets iOS 26.2, `ABYGlassBarBackground` uses Apple's native **Liquid Glass** (`.glassEffect`) rather than a static `.ultraThinMaterial`, so floating bars refract and pick up specular highlights from the content behind them.

The **jewel** gradients are reserved for two places only: the Sacred Orb, and a restrained iridescent sheen on the **active tab** (`IridescentBubble`). Both draw from the calm orb palette (teal / sky / periwinkle / sage) at low opacity — a holographic hint on glass, never a saturated color fill. Everything else in the bar stays neutral.

### 4. One dominant action per screen

Psychology audit insight: competing CTAs erode morning focus. Each screen should answer “what do I do next?” in one beat:

- **Home** — Begin devotion / rhythm rings
- **Chaplain tab** — Talk or type with Chaplain
- **Journal** — Capture today’s reflection
- **Chat** — Composer at bottom; chips only when empty

Secondary content (insights, prayer wall preview, history) stays below the fold or behind a single row.

### 5. Pastoral tone in copy and layout

- No em-dashes in UI strings; prefer commas and short sentences.
- Chaplain is a **companion for reflection, not clinical care** (`ABYChaplainIdentityBubble`).
- Avoid guilt language on streaks; celebrate showing up (“You showed up”).

---

## Psychology & habit design

Sacred Start is shaped by behavioral design, not gamification. The goal is **return without shame** and **depth without overwhelm**.

### Arrival before action

Morning users often arrive distracted. The devotion flow opens with **arrival** (greeting, pace choice) before asking for mood or output. This mirrors [Calm](https://mobbin.com/screens/40ba5ad3-03c7-4b81-ac40-6a2b447233fa) and [Breathwrk](https://mobbin.com/screens/c72faf37-1017-4e2a-82fe-6d4022bee8a7): lower the threshold before the ritual begins.

### One path, one primary beat

At check-in, users choose **pray** or **reflect** — not both in sequence. Competing paths in one screen create decision fatigue. After commitment, the UI removes the alternate path until the next day.

| Path | Psychological intent | UI pattern |
|------|---------------------|------------|
| **Pray** | Embodied presence, breath, spoken repetition | Threshold prayer: 3 breaths + repeatable first-person lines (`ThresholdPrayerFlowView`) |
| **Reflect** | Cognitive processing, ownership of words | Same `GuidedJournalEntryView` as journal “Guided Entry” — type or dictate, no separate “morning reflection” chrome |

Unifying reflect with Guided Entry reduces **mode confusion**: one write surface, one muscle memory.

### “No perfect words”

Prompt copy and subheads repeat permission: *“No perfect words — just what's true.”* This lowers performance anxiety ([5 Minute Journal](https://mobbin.com/screens/7f5129e8-0de8-4050-8fe7-d0cf033442f3), [Alan Mind voice journal](https://mobbin.com/screens/3604062f-6162-46ff-b80b-67d8d77777db)). Starter phrases (`I'm noticing…`, `I'm grateful for…`) scaffold without prescribing content.

### Breath as regulation, not theater

Guided prayer uses breath beats before spoken lines. Breath regulates arousal before language — not as a loading animation. We removed blocking “weaving your prayer” overlays because **uncertainty + wait** triggers abandonment; repeatable lines restore **user agency** (they speak aloud, they control pace).

### Peak–end and completion

Devotion ends on a **word to carry** (scripture reveal + affirmation), not a form submit. Completion screen celebrates streak without guilt copy. Optional **depth** (voice, chat, gratitude line) is explicitly skippable — no extra credit framing.

### Voice vulnerability

Dictation paths always offer **Keep as spoken** before optional polish. Spoken prayer is emotionally exposed; auto-rewrite reads as judgment. On-device tidy first, ephemeral AI only when the user opts in.

### Habit loop gaps (tracked)

See GitHub issue #3 and [improvements/backlog.md](improvements/backlog.md): free first devotion, post-completion handoff, evening parity, and home rhythm above the fold are intentional next steps — not oversights in v1.1.

---

## Mobbin-informed patterns (and why)

We cite Mobbin URLs in Swift file headers so designers and engineers share the same reference frame.

### Habit & reflection

| Pattern | Reference | Our use |
|---------|-----------|---------|
| Streak calendar | [ABY streak](https://mobbin.com/screens/49fcbbc9-a0d3-4a10-88a9-a791c3c8f1a6) | `StreakScreenView` — single white card hero |
| Mad-libs journal | [ABY mad-libs](https://mobbin.com/screens/5c0e4735-be8c-426b-9e69-83c2c7ca148e) | `GuidedJournalFlowView` — flowing sentence + tappable pills |
| Timeline | [ABY timeline](https://mobbin.com/screens/a79d0a61-c35f-4ab7-bf44-9100c457fb53) | `ConversationsListView` — date rails + entry cards |
| Liven prompt card | [Liven](https://mobbin.com/screens/8d10063c-ceff-4668-a314-0714cded6d09) | `JournalTodayCaptureCard` |

### Chat & AI

| Pattern | Reference | Our use |
|---------|-----------|---------|
| Gemini empty state | [Gemini](https://mobbin.com/screens/8cb0be56-3634-46eb-bc04-7fd121164726) | Greeting + flat wash + centered placeholder |
| Gemini chips | [Gemini chips](https://mobbin.com/screens/7097fe26-5a50-4577-a64e-e47ffcf9097f) | Max ~3 suggestion chips above composer |
| Copilot recents | [Copilot](https://mobbin.com/screens/40046f7b-1621-4099-a9e9-76910e645eb3) | Grouped history, search, swipe delete |
| ABY chat bubbles | [ABY chat](https://mobbin.com/screens/f1a56ab6-6c52-46e7-9f6d-66fb287b00b0) | Warm user bubble, prose Chaplain reply |

**Why Gemini for chat, ABY for journal?** Chat is turn-based and text-first; users expect a neutral canvas and bottom composer. Journal is emotional and spatial; gradient and serif signal “this is yours.” Mixing them—gradient chat with blue fade bands—felt noisy in review.

### Recap & stories

| Pattern | Reference | Our use |
|---------|-----------|---------|
| Week story pager | [How We Feel](https://mobbin.com/screens/f07c9b43-464b-4056-a5c1-80a13ee5002f) | `MorningWrappedView` — one beat per page |
| Recap cards | [Opal](https://mobbin.com/screens/403d27ac-0a46-4cdd-9e8e-a7521bbc8aee) | Stat typography, progress rings |
| Replay momentum | [Apple Music Replay](https://mobbin.com/screens/a9ad905f-120e-4ead-b895-8f1d63fb40ad) | Closing beat, share-ready summary |

**Why paged beats vs scroll dump?** Weekly reflection is emotional data; scrolling a long report feels like homework. Paging gives pause, haptic rhythm, and a sense of ceremony aligned with “reviewing your week with God.”

---

## Interaction philosophy

### Haptics

Use `DevotionHaptics` sparingly and semantically:

- **Soft** — story page turns, gentle confirmations
- **Success** — devotion completion, streak milestone
- Avoid haptic noise on every chip tap

### Blur reveals

`blurReveal` on speech polish preview signals transformation without hiding that the user’s words are still theirs. The animation sells “tidying,” not “AI rewrote your prayer.”

### User agency on speech polish

Voice is vulnerable. The flow is always:

1. Capture raw transcript
2. Offer **Keep as spoken** (default path, no network)
3. Optional **Tidy gently** — on-device first, ephemeral AI only when needed

We never auto-replace spoken prayer text. See `ABYSpeechPolishReview` and `TranscriptPolishService`.

### Presence honesty

While the model thinks or looks up Scripture, show **labeled presence** (`ChaplainPresenceIndicator`), not a generic spinner. Users tolerate wait when the app names the work (“Looking up John 3:16…”).

### Motion

- **Snappy springs** (`AppTheme.springSnappy`) — tab selection, button press
- **Gentle springs** (`springGentle`) — sheet present, story page change
- **Staggered appear** — streak hero, wrapped beats (opacity + small offset)
- Onboarding uses faster step-out / slower step-in to avoid jarring cuts

---

## Chat design

### Gemini flat canvas

- Background: single `tabWashTop` field in light mode
- No markdown rendering — `ChaplainMessageFormatter.plainText` at display time
- No edge gradient fades or “AI blue” glow
- Empty state: “Hi {name}” + “Where should we start?” left-aligned in the scroll area; chips in a horizontal rail **above** the composer

### Presence states

```
thinking → searchingScripture(label) → streaming tokens → done
loadingThread (resume only)
```

Scripture citations render as **cards beneath the composer** during lookup, then attach to the assistant message.

### History hygiene

- Chaplain threads live in Chaplain history, not Journal timeline
- Internal prompts (guided prayer JSON, transcript polish) filtered out
- Delete with confirmation; no mood subtitles on rows—title + optional preview snippet only

### Ephemeral mode

Background AI (polish, guided prayer composition) must not pollute history. `ephemeral: true` in context; edge skips persistence; client deletes leaked IDs.

---

## Story / recap patterns

`MorningWrappedView` story beats:

1. Intro — brand + week range  
2. Mornings — days showed up  
3. Rhythm — ring completion  
4. Mood — dominant emotional tone  
5. Streak — continuity  
6. Chaplain — conversation count / themes  
7. Narrative (optional) — AI summary when available  
8. Closing — invitation to next week  

Each beat is **one screen**, scroll only for overflow copy, footer CTA advances. Progress segments in chrome (not iOS page dots) keep the metaphor of “chapters.”

---

## What we intentionally avoid

| Avoid | Why |
|-------|-----|
| Gradient on gradient | Visual fatigue; ABY uses one atmospheric layer |
| Markdown in Chaplain UI | Feels like a dev tool, breaks pastoral tone |
| Auto-focus chat on open | Keyboard jumps; Gemini leaves composer resting |
| Mood subtitles in chat history | Redundant with title; clutters Copilot-style rows |
| Chat threads on Journal tab | Splits mental model; Journal = your words, Chaplain = dialogue |
| Guilt-based streak copy | Sacred habit, not Duolingo panic |
| Saturated nav tab tints | Neutral glass keeps focus on center orb |
| Night mode everywhere | `SanctuaryAppearance.nightGradientEnabled = false` until fully designed |
| Voice as default chat | Text-first Chaplain; voice behind flag until UX parity |

---

## How to extend the system

### Adding a new screen

1. **Pick background style** — `ABYBackground(style:)` or explicit wash/gradient component  
2. **Use tokens** — `ABY.Spacing.screen`, `ABY.Radius.card`, `ABY.Font.*`, `sanctuaryPalette` environment  
3. **One primary CTA** — `ABYPrimaryButton` or clear composer  
4. **Mobbin cite** — add URL in file header if you studied a reference screen  
5. **Update changelog** — [CHANGELOG.md](CHANGELOG.md) under Unreleased  

### Adding a new chat capability

1. Extend `ChaplainContextBuilder` intent, not ad-hoc prompts in views  
2. If background-only, set `ephemeral: true`  
3. Strip formatting through `ChaplainMessageFormatter`  
4. Add presence mode if the operation takes >300ms  
5. Document in [system-design/](system-design/) if it crosses client/edge boundary  

### Adding a recap or onboarding beat

1. Prefer **pager beat** over long `ScrollView`  
2. Reuse `WrappedStoryChrome` patterns for progress + close  
3. Haptic on beat change  
4. Keep serif headline + short body + one stat or visual  

### Feature flags

`FeatureFlags.swift` gates incomplete surfaces (`bibleReaderEnabled`, `voiceChatEnabled`). Ship UI polish before flipping flags.

---

## File map (quick reference)

| Concern | Primary files |
|---------|----------------|
| Tokens & backgrounds | `Theme/ABYDesign.swift`, `Theme/AppFont.swift` |
| Chat UI | `Components/ABYChatComponents.swift`, `Views/ChaplainChatView.swift` |
| Journal UI | `Components/ABYJournalComponents.swift`, `Components/JournalComponents.swift` |
| Navigation | `Components/BottomNavigationBar.swift`, `Navigation/SacredOrbState.swift` |
| Motion / haptics | `Theme/AppTheme.swift`, `Components/DelightComponents.swift` |
| Scripture in chat | `Components/ChaplainScriptureComponents.swift`, `Services/Scripture/ScriptureCorpus.swift` |
| Week in review | `Views/MorningWrappedView.swift`, `Components/MorningWrappedComponents.swift` |
| Speech polish | `Components/VoiceComponents.swift`, `Services/Speech/TranscriptPolishService.swift` |

---

## Related documentation

- [CHANGELOG.md](CHANGELOG.md) — what shipped, when  
- [design-system/overview.md](design-system/overview.md) — token table and component index  
- [system-design/chaplain-scripture-tools.md](system-design/chaplain-scripture-tools.md) — Scripture tool architecture  
- [improvements/backlog.md](improvements/backlog.md) — ideas not yet built  
- [../PRODUCT_OVERVIEW.md](../PRODUCT_OVERVIEW.md) — product positioning  
