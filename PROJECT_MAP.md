# Sacred Start — Project Map

iOS-only repo. Marketing site: `../sacred-start-web` (moved out of this folder).

**Xcode target name:** DevotionLock · **Marketing name:** Sacred Start · **Bundle ID:** `com.devotionlock.mobile`

---

## Repository layout

```
devotionlock-mobile/
├── README.md                          # Quick start
├── PROJECT_MAP.md                     # This file
├── AppFontInfo.plist                  # App Info.plist (fonts, encryption export flag)
├── devotionlock-mobile.xcodeproj/     # Xcode project (app + widget extension targets)
│
├── DevotionLock/                      # Main iOS app target
│   ├── DevotionLockApp.swift          # @main entry, Supabase client bootstrap
│   ├── ContentView.swift              # Auth → onboarding → tabs routing
│   ├── Components/                    # Reusable UI (nav bar, journal, chaplain, auth…)
│   ├── Models/                        # Domain types (prayer, journey, rhythm, profile…)
│   ├── Services/                      # Business logic, sync, shield, speech
│   │   ├── AuthManager.swift
│   │   ├── Chaplain/                  # AI chat client + context builder
│   │   ├── Insight/                   # On-device + remote insights
│   │   ├── Shield/                    # Screen Time app blocking
│   │   ├── Speech/                    # Voice transcription
│   │   └── Supabase/                  # Repositories, sync, offline queues
│   ├── Store/                         # StoreKit / InAppKit products + PaywallAccess
│   ├── Theme/                         # Colors, fonts, ABY design system
│   ├── Views/                         # Screens (home, flows, settings, auth…)
│   │   └── Auth/                      # Sign up / sign in flow
│   ├── Assets.xcassets/
│   ├── Fonts/
│   ├── DevotionLock.storekit          # Local StoreKit config (3-day trial on annual)
│   ├── DevotionLock.entitlements      # Debug / base entitlements
│   └── DevotionLock.family-controls.entitlements  # Release (Family Controls)
│
├── DevotionLockShared/                # App Group types shared with widgets
│   ├── SharedConstants.swift
│   ├── WidgetSnapshot.swift
│   └── JournalActivityAttributes.swift
│
├── DevotionLockWidgets/               # Widget + Live Activity extension
│   ├── DevotionLockWidgets.swift      # Streak, verse, prayer wall widgets
│   ├── JournalLiveActivityWidget.swift
│   └── WidgetIntents.swift
│
├── DevotionLockWidgetsExtension-Info.plist
│
├── supabase/                          # Backend (deploy separately)
│   ├── migrations/                    # Postgres schema + RLS
│   ├── functions/                     # Edge functions (chaplain-chat, delete-account…)
│   └── seed/
│
├── scripts/
│   ├── deploy-supabase.sh
│   └── apply-migrations-sql-editor.md
│
├── ci_scripts/
│   └── ci_post_clone.sh               # Xcode Cloud post-clone hook
│
└── docs/
    ├── PRODUCT_OVERVIEW.md            # Feature + positioning reference
    └── LAUNCH_CHECKLIST.md            # Manual App Store / Supabase checklist
```

---

## App architecture (high level)

```
DevotionLockApp
  └── ContentView          → AuthFlowView | OnboardingFlowView | MainTabView
        └── MainTabView    → Home, Journal, Insights, Profile + modals
              ├── MorningFlowView / GuidedJournalFlowView
              ├── ChaplainChatView
              ├── PrayerWallView / PrayerCircleViews
              └── ShieldSettingsView (Family Controls)

AuthManager ──sign-in──► SyncCoordinator ──► Supabase repositories
Local stores (Journal, Streak, Prayer circles) ◄── offline queues ──► flush on foreground
PaywallAccess ◄── InAppKit / StoreKit (weekly + annual, 3-day trial)
```

---

## Feature map — implemented (v1)

| Area | Key files | Status |
|------|-----------|--------|
| **Auth** | `AuthManager.swift`, `Views/Auth/*` | Email sign up/in, session listener, sign out, delete account |
| **Onboarding** | `OnboardingFlowView.swift` | Mood, Chaplain voice, intention — completes into paywall |
| **Paywall / IAP** | `DevotionPaywallView.swift`, `DevotionProducts.swift`, `DevotionLock.storekit` | 3-day trial CTA, Apple disclosure, restore, premium gating via `PaywallAccess` |
| **Home** | `HomeView.swift`, `HomeComponents.swift` | Streak strip, rhythm rings, insights, shield card, timeline |
| **Morning devotion** | `MorningFlowView.swift`, `MorningProfile.swift` | Adaptive card flow, mood, scripture, reflection, voice/text |
| **Journal** | `ConversationsListView.swift`, `JournalLocalStore.swift` | Unified timeline, entry hub, search (premium-gated) |
| **Chaplain AI** | `ChaplainChatView.swift`, `ChaplainService.swift`, `supabase/functions/chaplain-chat` | Streaming chat, voice personas, AI disclosure, resume thread |
| **Prayer wall** | `PrayerWallView.swift`, `PrayerWallRepository.swift` | Pins, filters, answered celebration |
| **Prayer circles** | `PrayerCircleViews.swift`, `CircleRepository.swift` | Groups, posts, realtime, invite codes |
| **App Shield** | `AppShieldManager.swift`, `ShieldSettingsView.swift` | Screen Time block until devotion done (premium + entitlements) |
| **Streaks** | `StreakManager.swift`, `StreakScreenView.swift` | Daily completion, celebrations, week strip |
| **Journey / Wrapped** | `JourneyTimelineViews.swift`, `MorningWrappedView.swift` | Timeline preview, week in review |
| **Insights** | `AIInsightsView.swift`, `LocalInsightEngine.swift` | On-device themes + guided prayer entry points |
| **Widgets** | `DevotionLockWidgets/*`, `SharedDataSync.swift` | Streak, verse, prayer wall; App Group sync |
| **Deep links** | `DeepLinkRouter.swift` | Widget / URL → tab flows |
| **Settings / legal** | `AccountSettingsView.swift`, `LegalDocumentViews.swift` | Profile, reminders, widgets, privacy/terms in-app |
| **Sync / offline** | `SyncCoordinator.swift`, `*OfflineQueue.swift`, repositories | Debounced flush, pull on sign-in, foreground refresh |
| **Memory hardening** | `ConversationRepository.swift`, `CircleRepository.swift` | Lazy transcripts, Realtime channel cleanup |

---

## Not yet implemented / deferred

| Item | Notes |
|------|-------|
| **Sign in with Apple** | Auth is email-only today; `AuthProvider.apple` scaffolded |
| **Sign in with Google** | UI stub in `AuthSocialView.swift` |
| **Public privacy / terms URLs** | In-app legal exists; App Store needs hosted URLs (see `../sacred-start-web` or host separately) |
| **App Store Connect IAP** | Products + 3-day trial must be configured manually — see `docs/LAUNCH_CHECKLIST.md` |
| **Family Controls entitlement** | Release profile must include capability; test on device |
| **LiveKit voice AI** | Voice uses on-device transcription + text Chaplain today |
| **Full night sanctuary theme** | Scaffolded in `SanctuaryAppearanceSettingsView.swift` |
| **Live Activities (journal)** | `JournalLiveActivityManager.swift` + widget extension scaffold |
| **Rename bundle / target to Sacred Start** | Marketing rename only so far; code IDs still `DevotionLock` |
| **Push notification production** | Local reminders exist; APNs production setup TBD |
| **Analytics / crash reporting** | Not integrated |
| **Unit / UI tests** | No test target in repo yet |

---

## Supabase backend

| Migration | Purpose |
|-----------|---------|
| `20260607024821_initial_schema.sql` | Core tables: profiles, devotions, journal, conversations |
| `20260607025404_harden_handle_new_user.sql` | Auth trigger hardening |
| `20260607031058_prayer_circles_phase2.sql` | Circles, memberships, posts |
| `20260607040000_profiles_account_management.sql` | Account fields, deletion support |
| `20260607130000_sync_extensions.sql` | Sync columns / preferences |

| Edge function | Purpose |
|---------------|---------|
| `chaplain-chat` | DeepSeek-backed streaming Chaplain |
| `generate-insight` | Optional remote insight generation |
| `delete-account` | GDPR-style account wipe |

Deploy: `./scripts/deploy-supabase.sh` (after `supabase link`).

---

## Premium gating

All feature entry points should use `PaywallAccess.guardPremium` in:

- `MainTabView.swift` — tabs, devotion, Chaplain, prayer wall, streaks, deep links
- `HomeView.swift` — rhythm ring taps
- `ConversationsListView.swift` — journal add / hub
- `AIInsightsView.swift` — insights actions
- `SearchView.swift` — search + tag chips
- `ShieldSettingsView.swift` — shield config

Browsing without subscription is allowed; actions route to paywall.

---

## Build targets

| Target | Product |
|--------|---------|
| DevotionLock | Main app |
| DevotionLockWidgets | Widget + Live Activity extension |

Open `devotionlock-mobile.xcodeproj`, scheme **DevotionLock**, run on a **physical device** for Shield and IAP sandbox.

---

## Related repos / folders

| Path | Purpose |
|------|---------|
| `../sacred-start-web` | Next.js marketing site (Popcorn-style landing) |
| `docs/PRODUCT_OVERVIEW.md` | Full product write-up |
| `docs/LAUNCH_CHECKLIST.md` | Pre-submit checklist |

---

*Last updated: June 2026 — v1 App Store hardening complete in code; manual launch steps remain.*
