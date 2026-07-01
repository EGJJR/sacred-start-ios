# Sacred Start (DevotionLock) — Issues and Improvements Report

Generated: 2026-06-29

## Executive Summary

This report identifies critical issues, potential problems, and recommended improvements for the Sacred Start iOS application. Issues are categorized by severity and impact area.

---

## 🔴 Critical Issues (Blocking App Store Launch)

### 1. Missing Public Privacy Policy & Terms of Service URLs

**Current State:**
- In-app legal documents exist (`LegalDocumentViews.swift`)
- App Store Connect requires public URLs
- Mentioned in `docs/LAUNCH_CHECKLIST.md` as incomplete

**Impact:** App Store submission will be rejected without these URLs

**Recommendation:**
- Host privacy policy and terms on `../sacred-start-web` or separate domain
- Update App Store Connect metadata
- Add URLs to app settings for user reference

**Files Affected:**
- Marketing website (separate repo)
- App Store Connect configuration

---

### 2. Family Controls Entitlement Configuration Complexity

**Current State:**
- Complex setup process documented in `FAMILY_CONTROLS_APP_SHIELD.md`
- Must switch between `DevotionLock.entitlements` and `DevotionLock.family-controls.entitlements`
- TestFlight builds require Family Controls Distribution approval
- Easy to misconfigure and break App Shield feature

**Issues:**
- Documentation spread across multiple files
- Manual entitlement switching required
- CI/CD pipeline uses base entitlements only
- No automated validation of correct entitlement file usage

**Recommendation:**
- Add Xcode build phase script to validate correct entitlements for each configuration
- Create checklist/script to verify Family Controls setup before release
- Document rollback plan if FC distribution is rejected
- Consider conditional compilation for Shield features based on entitlements

**Files Affected:**
- `devotionlock-mobile.xcodeproj/project.pbxproj`
- `DevotionLock/DevotionLock.entitlements`
- `DevotionLock/DevotionLock.family-controls.entitlements`
- `.github/workflows/ios.yml`

---

### 3. In-App Purchases Not Yet Configured in App Store Connect

**Current State:**
- Local StoreKit configuration exists (`DevotionLock.storekit`)
- Product IDs defined in `DevotionProducts.swift`
- Not yet set up in App Store Connect
- 5-day trial introductory offer configuration required

**Impact:** Users cannot purchase subscriptions after TestFlight/App Store launch

**Recommendation:**
- Create subscription group in App Store Connect immediately
- Configure all three products (weekly, monthly, annual)
- Set up 5-day trial introductory offer on annual plan
- Test sandbox purchasing before launch
- Document IAP review guidelines compliance

**Files Affected:**
- App Store Connect (external configuration)
- `DevotionLock/Store/DevotionProducts.swift` (reference)

---

## 🟠 High Priority Issues (Technical Debt & Stability)

### 4. No Automated Testing Infrastructure

**Current State:**
- Zero unit tests
- Zero UI tests
- No test target in Xcode project
- GitHub Actions CI only verifies compilation, not correctness

**Impact:**
- High risk of regression bugs
- Difficult to refactor with confidence
- No safety net for edge cases
- Memory issues may go undetected

**Recommendation:**
- Add XCTest target to Xcode project
- Prioritize testing for:
  - `StreakManager` (streak logic is business-critical)
  - `SyncCoordinator` (data loss prevention)
  - `AuthManager` (authentication flow)
  - `PaywallAccess` (premium gating logic)
  - `BibleReferenceParser` (parsing accuracy)
  - Offline queue flush logic
- Add UI tests for critical flows:
  - Sign up → onboarding → paywall → trial activation
  - Morning devotion completion → streak increment
  - App Shield authorization flow
- Update CI workflow to run tests

**Files to Create:**
- `DevotionLockTests/` directory
- Test target in Xcode project

---

### 5. GitHub Actions CI Uses Potentially Invalid Runner

**Current State:**
- `.github/workflows/ios.yml` specifies `runs-on: macos-26`
- macOS 26 is not a standard GitHub Actions runner (latest is `macos-15` or `macos-latest`)
- CI may be failing silently or not running at all

**Impact:**
- No actual CI validation happening
- False sense of security
- Breaking changes may be merged

**Recommendation:**
- Update to `macos-latest` or specific version like `macos-15`
- Verify Xcode version availability on chosen runner
- Add status badge to README.md to make CI status visible
- Test workflow immediately after change

**Files Affected:**
- `.github/workflows/ios.yml` (line 24)

---

### 6. Potential Memory Issues with Large Conversations

**Current State:**
- `PROJECT_MAP.md` mentions "Memory hardening" for `ConversationRepository` and `CircleRepository`
- Lazy transcript loading implemented
- Realtime channel cleanup mentioned
- No documented load testing or memory profiling results

**Issues:**
- Long Chaplain conversations could cause memory pressure
- Prayer circles with many posts may load entire history
- No pagination strategy for timeline views
- Widget snapshots may include too much data

**Recommendation:**
- Implement pagination for:
  - `ConversationsListView` (journal timeline)
  - Chaplain message history
  - Prayer circle posts
- Add memory warnings handling in `DevotionLockApp.swift`
- Profile memory usage with Instruments for:
  - 50+ message Chaplain threads
  - Circles with 100+ posts
  - Journal with 90+ days of entries
- Set maximum message limits for widget snapshots
- Consider message windowing (keep last N messages in memory)

**Files Affected:**
- `DevotionLock/Services/ConversationRepository.swift`
- `DevotionLock/Services/Supabase/CircleRepository.swift`
- `DevotionLock/Views/ConversationsListView.swift`
- `DevotionLock/Views/ChaplainChatView.swift`

---

### 7. Error Handling in Edge Functions Needs Improvement

**Current State:**
- Basic error handling in edge functions
- Generic error messages returned to client
- No structured error types or codes
- Limited logging for debugging production issues

**Issues:**
- `chaplain-chat/index.ts`: Generic error catching without specific handling
- `generate-insight/index.ts`: Throws raw errors without sanitization
- `delete-account/index.ts`: Returns error messages that may expose internal details
- No error tracking or monitoring service integrated

**Recommendation:**
- Create standardized error response format:
  ```typescript
  {
    error: { code: "AUTH_FAILED", message: "User friendly message", details?: {} }
  }
  ```
- Add Sentry or similar error tracking
- Implement retry logic for transient failures
- Add rate limiting to prevent abuse
- Log errors with correlation IDs for debugging
- Sanitize error messages before sending to client

**Files Affected:**
- `supabase/functions/chaplain-chat/index.ts`
- `supabase/functions/generate-insight/index.ts`
- `supabase/functions/delete-account/index.ts`
- Create `supabase/functions/_shared/errors.ts`

---

### 8. No Analytics or Crash Reporting

**Current State:**
- `PROJECT_MAP.md` explicitly states "Analytics / crash reporting — Not integrated"
- No visibility into production crashes
- No usage metrics or funnel analysis
- Cannot measure feature adoption or user behavior

**Impact:**
- Blind to production issues
- Cannot prioritize features based on usage data
- No conversion funnel tracking (onboarding → trial → paid)
- Cannot detect app-breaking bugs until users complain

**Recommendation:**
- Integrate crash reporting: Firebase Crashlytics or Sentry
- Add analytics: Mixpanel, Amplitude, or PostHog
- Track key events:
  - Sign up, onboarding completion, trial start
  - Devotion completion, streak milestones
  - Chaplain usage, prayer circle engagement
  - App Shield activation/usage
  - Paywall views, purchase attempts, successful purchases
- Add privacy-respecting opt-out mechanism
- Update privacy policy with analytics disclosure

**Files to Create:**
- `DevotionLock/Services/AnalyticsService.swift`
- `DevotionLock/Services/CrashReportingService.swift`

---

## 🟡 Medium Priority Issues (User Experience & Features)

### 9. Incomplete Voice Chat Feature

**Current State:**
- `FeatureFlags.voiceChatEnabled = false`
- Voice transcription exists (`SpeechTranscriptionService`)
- Voice capture UI scaffolded but disabled
- Chaplain voice personas selected during onboarding but not used

**Issues:**
- Users select voice persona during onboarding but never hear it
- Confusing UX: voice option presented but not delivered
- Text-to-speech infrastructure not implemented
- LiveKit voice AI mentioned as "deferred"

**Recommendation:**
- **Option A - Remove from onboarding until ready:**
  - Remove voice persona selection from onboarding
  - Keep voice transcription for journal dictation
  - Add voice chat in v1.1+ when complete
- **Option B - Implement basic voice chat:**
  - Integrate text-to-speech (AVSpeechSynthesizer or cloud TTS)
  - Enable voice mode for Chaplain responses
  - Skip LiveKit for v1, use simpler solution
- Update product description to match actual capabilities

**Files Affected:**
- `DevotionLock/Config/FeatureFlags.swift`
- `DevotionLock/Views/OnboardingFlowView.swift`
- `DevotionLock/Views/ChaplainChatView.swift`
- `DevotionLock/Services/Chaplain/ChaplainService.swift`

---

### 10. Night Mode/Sanctuary Appearance Not Fully Implemented

**Current State:**
- `SanctuaryAppearanceSettingsView.swift` exists
- Night gradient toggle scaffolded
- `DESIGN-PHILOSOPHY.md` states: "Night mode everywhere — nightGradientEnabled = false until fully designed"
- Dark mode support incomplete

**Issues:**
- Settings screen suggests feature exists but doesn't work
- System dark mode may cause readability issues
- Sanctuary gradients not optimized for dark appearance

**Recommendation:**
- **Option A - Hide incomplete settings:**
  - Remove appearance settings from UI until ready
  - Ensure app works with system dark mode
  - Test all screens in dark mode for readability
- **Option B - Complete night mode:**
  - Design dark sanctuary gradient palette
  - Update all ABY components for dark mode
  - Add appearance preview in settings
- Audit all text colors for dark mode contrast

**Files Affected:**
- `DevotionLock/Views/SanctuaryAppearanceSettingsView.swift`
- `DevotionLock/Theme/ABYDesign.swift`
- `DevotionLock/Theme/AppTheme.swift`

---

### 11. Sign in with Apple Not Implemented

**Current State:**
- Email-only authentication
- `AuthProvider.apple` scaffolded but not functional
- `AuthSocialView.swift` has UI stub for Google sign-in
- Apple Sign In is **expected** by iOS users and often preferred

**Impact:**
- Friction during sign-up (users must create/remember password)
- Lower conversion rates
- Missing "industry standard" for iOS apps
- App Store may require Sign in with Apple if other social logins exist

**Recommendation:**
- Implement Sign in with Apple before adding other social logins
- Add to onboarding and sign-in screens
- Update Supabase auth configuration
- Test with Apple ID sandbox accounts
- Consider making email sign-up optional and Apple Sign In primary

**Files Affected:**
- `DevotionLock/Services/AuthManager.swift`
- `DevotionLock/Views/Auth/AuthFlowView.swift`
- `DevotionLock/Components/AuthComponents.swift`
- Supabase Auth configuration (dashboard)

---

### 12. Habit Loop and Retention Features Incomplete

**Current State:**
- `docs/design/improvements/backlog.md` identifies habit loop gaps
- Issue #3 mentioned but not visible (GitHub access denied)
- Backlog items:
  - Free first devotion; paywall after completion peak
  - Home → 3 blocks above fold
  - Post-devotion handoff on completion screen
  - Evening reflection parity with morning

**Impact:**
- User retention may suffer without proper habit loop
- Paywall placement may be suboptimal
- Evening reflection feature incomplete (only morning flow polished)

**Recommendation:**
- Review habit loop psychology with completion peak paywall strategy
- Implement evening reflection with same quality as morning devotion
- Add post-devotion handoff suggestions (journal, Chaplain, prayer)
- A/B test paywall placement if analytics added
- Complete 3-ring rhythm visualization on Home

**Files Affected:**
- `DevotionLock/Views/HomeView.swift`
- `DevotionLock/Views/MorningFlowView.swift`
- Create `DevotionLock/Views/EveningFlowView.swift`
- `DevotionLock/Models/DailyRhythm.swift`

---

### 13. Streak Logic Edge Cases Not Documented

**Current State:**
- Streak tracking in `StreakManager.swift`
- Demo seed data creates 21-day streak
- No documented behavior for:
  - Timezone changes during travel
  - Device clock manipulation
  - What happens at midnight boundary
  - Grace period for missed days

**Issues:**
- Users traveling across timezones may lose streaks unfairly
- Clock manipulation could fake streaks
- Unclear if there's a grace period or late-night cutoff

**Recommendation:**
- Document streak rules explicitly:
  - Definition of "day" (calendar day in user's timezone? UTC?)
  - Grace period policy (can complete morning devotion until 3am next day?)
  - Timezone travel handling
  - Clock tampering detection/mitigation
- Add unit tests for streak edge cases
- Consider "freeze" or "repair" streak options (premium feature?)
- Add streak FAQ to in-app help

**Files Affected:**
- `DevotionLock/Services/StreakManager.swift`
- `DevotionLock/Models/StreakIdentity.swift`
- Documentation (create `docs/STREAK_RULES.md`)

---

## 🟢 Low Priority Issues (Polish & Optimization)

### 14. Branding Inconsistency: "Devotion Lock" vs "Sacred Start"

**Current State:**
- Marketing name: "Sacred Start"
- Code/target name: "DevotionLock"
- Bundle ID: `com.devotionlock.mobile`
- Some legal strings and internal references still use "Devotion Lock"

**Issues:**
- `docs/design/improvements/backlog.md` notes: "Replace 'Devotion Lock' in legal/shield strings with Sacred Start"
- User-facing strings may mix branding
- Confusing for users if internal name leaks

**Recommendation:**
- Audit all user-facing strings for "Devotion Lock" and replace with "Sacred Start"
- Update legal documents to use consistent branding
- Consider eventual bundle ID migration (complex, requires new app record)
- Document branding guidelines for future content

**Files to Audit:**
- `DevotionLock/Views/LegalDocumentViews.swift`
- `DevotionLock/Views/ShieldSettingsView.swift`
- All UI strings (grep for "Devotion Lock")

---

### 15. Widget Font Loading May Fail on Device

**Current State:**
- Widgets use custom fonts (Inter Tight, Instrument Serif)
- `docs/design/improvements/backlog.md` notes: "Widget fonts → `ABY.Font` bundle"
- Custom font loading in widget extensions is complex
- May render with system font if fonts not properly bundled

**Issues:**
- Fonts must be in widget extension target
- `AppFontInfo.plist` may not apply to widgets
- Font registration in widget requires explicit loading

**Recommendation:**
- Verify fonts are included in widget extension target
- Test widgets on physical device (simulator may differ)
- Add fallback fonts in widget views
- Consider using SF Pro for widgets if custom fonts cause issues
- Document widget font setup process

**Files Affected:**
- `DevotionLockWidgets/WidgetPalette.swift`
- `DevotionLockWidgets/DevotionLockWidgets.swift`
- Widget extension build settings

---

### 16. No Rate Limiting or Abuse Protection for AI Features

**Current State:**
- Chaplain chat streams from DeepSeek via edge function
- No apparent rate limiting or cost controls
- No per-user quotas or throttling
- Premium gating exists but no usage caps

**Issues:**
- Malicious user could spam AI requests and run up costs
- No protection against API key abuse
- Free trial users could abuse AI features before canceling
- DeepSeek API costs could spiral unexpectedly

**Recommendation:**
- Add rate limiting at edge function level:
  - Messages per minute per user
  - Maximum conversation length
  - Daily token limits
- Implement cost tracking and alerting
- Add usage metrics to admin dashboard
- Consider progressive limits (free trial: 10 chats, premium: unlimited)
- Add retry backoff for failed AI requests

**Files Affected:**
- `supabase/functions/chaplain-chat/index.ts`
- `supabase/functions/generate-insight/index.ts`
- Add `supabase/functions/_shared/rate-limiter.ts`

---

### 17. No Monitoring or Alerting for Backend Services

**Current State:**
- Supabase edge functions deployed but no uptime monitoring
- No alerts for edge function failures
- No visibility into DeepSeek API health
- DEEPSEEK_API_KEY could expire without warning

**Recommendation:**
- Set up Supabase monitoring dashboard
- Add health check endpoints to edge functions
- Implement alerting for:
  - Edge function error rate spikes
  - DeepSeek API failures
  - Database connection issues
  - Abnormal traffic patterns
- Create runbook for common failure scenarios
- Add status page for visibility

**Files to Create:**
- `supabase/functions/health-check/index.ts`
- `docs/RUNBOOK.md` (incident response guide)

---

### 18. Scripture Catalog Needs Broader Coverage

**Current State:**
- Curated passage catalog (`SpiritualPassageCatalog.swift`)
- KJV chapter lookup via bible-api CDN
- `PROJECT_MAP.md` notes: "Topic-based verse search (full Bible) — v1: curated catalog"
- Limited offline scripture availability

**Issues:**
- Users may not find specific passages they're looking for
- Topic search is limited to curated catalog
- Feature flag can disable full reader, breaking user expectations

**Recommendation:**
- Expand curated catalog with more passages and topics
- Consider shipping topical index JSON (topic → references)
- Evaluate API.Bible or other APIs for better search
- Document scripture feature capabilities clearly in app
- Add "Request a passage" feedback mechanism

**Files Affected:**
- `DevotionLock/Services/Bible/SpiritualPassageCatalog.swift`
- `scripts/export-scripture-catalog.mjs`
- `supabase/functions/_shared/scripture-corpus.ts`

---

### 19. Offline Queue Flush Logic Needs Verification

**Current State:**
- `DevotionOfflineQueue` and `CircleOfflineQueue` exist
- `SyncCoordinator` flushes on launch, foreground, sign-in
- No documented testing of offline scenarios
- Risk of data loss if queue logic has bugs

**Issues:**
- What happens if flush fails repeatedly?
- How long are items kept in queue?
- Is there a maximum queue size?
- What if user completes devotion offline, force-quits app, and signs out?

**Recommendation:**
- Add comprehensive offline tests:
  - Complete devotion offline → app quit → relaunch → verify sync
  - Create circle post offline → network error → retry success
  - Queue overflow handling
- Document queue behavior and limits
- Add queue inspection in debug settings
- Consider persisting queue to disk (if not already)
- Add manual "sync now" button in settings

**Files Affected:**
- `DevotionLock/Services/Supabase/DevotionOfflineQueue.swift`
- `DevotionLock/Services/Supabase/CircleOfflineQueue.swift`
- `DevotionLock/Services/Supabase/SyncCoordinator.swift`

---

### 20. Supabase Migration Deployment Process Fragile

**Current State:**
- Migrations must be applied in specific order
- Manual process documented with two options (CLI or SQL Editor)
- Easy to apply migrations out of order or skip one
- No automated migration verification

**Issues:**
- New developers may misconfigure database
- Production deployment risky without checklist
- No rollback strategy documented
- Migrations numbered by timestamp but may not reflect dependencies

**Recommendation:**
- Add migration verification script:
  ```bash
  #!/bin/bash
  # scripts/verify-migrations.sh
  # Checks that all migrations are applied in order
  ```
- Create idempotent migrations (safe to run multiple times)
- Add migration checksum verification
- Document rollback procedure for each migration
- Consider using Supabase migration status table
- Add pre-deployment migration checklist

**Files to Create:**
- `scripts/verify-migrations.sh`
- `docs/MIGRATION_GUIDE.md` (rollback procedures)

---

## 📋 Code Quality Improvements

### 21. Inconsistent Error Handling Patterns

**Observation:**
- Some functions throw errors, others return optionals
- Some use `guard` with early return, others nest `if-let`
- Error messages vary in format and detail

**Recommendation:**
- Establish error handling guidelines
- Use `Result<Success, Failure>` for operations that can fail
- Create custom error types for domain-specific errors
- Standardize error logging format

---

### 22. Large View Files

**Observation:**
- Several view files exceed 500 lines
- Multiple view components in single files
- Hard to navigate and maintain

**Recommendation:**
- Split large view files into smaller, focused components
- Use `// MARK:` comments more consistently
- Extract reusable components to separate files
- Target maximum 300 lines per view file

---

### 23. Magic Numbers and Strings

**Observation:**
- Hardcoded values throughout codebase
- Some spacing/sizing values not using ABY design tokens
- String literals in business logic

**Recommendation:**
- Move all spacing to `ABY.Spacing`
- Create constants for magic numbers
- Use string catalogs for localization preparation
- Extract business logic constants to dedicated files

---

## 🔒 Security & Privacy Improvements

### 24. API Key Storage and Rotation

**Current State:**
- `DEEPSEEK_API_KEY` stored in Supabase edge function secrets
- No documented key rotation policy
- Supabase anon key embedded in app

**Recommendation:**
- Document API key rotation procedure
- Set up calendar reminder for quarterly key rotation
- Add monitoring for API key usage/abuse
- Consider backup API provider for resilience

---

### 25. User Data Deletion Completeness

**Current State:**
- Delete account edge function exists
- Deletes auth user, profile, avatar files
- May not delete all related data (prayers, circle posts, etc.)

**Recommendation:**
- Audit data deletion completeness:
  - Are all user conversations deleted?
  - Are prayer circle posts from user removed?
  - Are AI insights purged?
  - Are widget snapshots cleared?
- Test deletion with various user states
- Document what's kept for analytics (anonymized)
- Add deletion confirmation email

**Files Affected:**
- `supabase/functions/delete-account/index.ts`

---

### 26. Premium Status Bypass in Debug Builds

**Current State:**
- Debug builds allow premium bypass in profile settings
- Useful for development but could be exploited if debug build leaks

**Recommendation:**
- Ensure debug builds cannot be distributed via TestFlight/App Store
- Add build number watermark in debug mode
- Consider requiring password or secret code to enable bypass
- Add analytics event when bypass is used (for monitoring abuse)

**Files Affected:**
- `DevotionLock/Store/PaywallAccess.swift`
- `DevotionLock/Views/ProfileView.swift`

---

## 📱 Platform & Infrastructure

### 27. No App Store Optimization (ASO) Strategy

**Current State:**
- App name: "Sacred Start"
- No documented keyword strategy
- No A/B testing plan for screenshots/description

**Recommendation:**
- Research keywords: "morning devotional", "Christian journal", "prayer app", "Bible study", "spiritual discipline"
- Create compelling screenshot sequence
- Write description emphasizing unique value props (AI Chaplain, App Shield)
- Plan for app store reviews prompt after positive moments (streak milestone, devotion completion)

---

### 28. No Backup or Disaster Recovery Plan

**Current State:**
- User data in Supabase
- No documented backup strategy
- No disaster recovery plan if Supabase has outage

**Recommendation:**
- Configure automated Supabase database backups
- Document recovery process for various failure scenarios
- Add export user data feature (GDPR compliance)
- Consider multi-region Supabase if usage grows
- Test restoration from backup

---

### 29. No Performance Benchmarks or Monitoring

**Current State:**
- No performance baselines established
- No monitoring for app launch time, API latency, etc.
- No alerting for performance degradation

**Recommendation:**
- Establish performance baselines:
  - Cold launch time
  - Chaplain response time (p50, p95, p99)
  - Sync operation latency
  - View rendering times
- Add performance metrics to analytics
- Set up alerts for regression
- Profile periodically with Instruments

---

## 🎨 Design & UX Polish

### 30. Accessibility Audit Needed

**Current State:**
- No documented accessibility testing
- Custom components may not support VoiceOver
- Color contrast ratios not verified
- Dynamic type support unclear

**Recommendation:**
- Full VoiceOver audit of all screens
- Verify color contrast ratios (WCAG AA minimum)
- Test with dynamic type sizes
- Add accessibility labels to custom components
- Test with Reduce Motion enabled

---

### 31. Onboarding Flow Could Be Shorter

**Current State:**
- Onboarding includes mood, voice persona, intention selection
- Users must complete all steps before reaching content
- May cause drop-off before trial activation

**Recommendation:**
- Consider progressive onboarding:
  - Minimal initial setup (just email/password)
  - Defer voice/mood/intention to first devotion
  - Get users to "aha moment" faster
- A/B test onboarding length if analytics added
- Measure drop-off at each step

**Files Affected:**
- `DevotionLock/Views/OnboardingFlowView.swift`

---

### 32. App Icon and Brand Assets Need Trademark Review

**Current State:**
- Sacred Heart brand mark used in app
- "Sacred Start" name chosen
- No documented trademark search or clearance

**Recommendation:**
- Conduct trademark search for "Sacred Start"
- Review sacred imagery usage guidelines
- Consult legal for religious iconography usage
- Consider backup names if trademark issues arise

---

## 📊 Recommended Priority Order

### Before App Store Submission (Critical Path):
1. ✅ Fix GitHub Actions CI runner version (5 minutes)
2. ✅ Host public privacy policy and terms URLs
3. ✅ Configure IAP in App Store Connect
4. ✅ Validate Family Controls entitlement setup
5. ✅ Complete TestFlight smoke test checklist

### Next Sprint (High Priority):
6. ✅ Add basic unit tests for critical business logic
7. ✅ Implement crash reporting (Firebase or Sentry)
8. ✅ Fix voice chat feature or remove from onboarding
9. ✅ Implement Sign in with Apple
10. ✅ Add error handling improvements to edge functions

### Post-Launch (Medium Priority):
11. ✅ Add analytics and funnel tracking
12. ✅ Complete night mode or hide incomplete settings
13. ✅ Improve habit loop with evening reflection
14. ✅ Add rate limiting and abuse protection
15. ✅ Implement comprehensive offline testing

### Ongoing (Polish & Optimization):
16. ✅ Expand scripture catalog
17. ✅ Performance monitoring and benchmarks
18. ✅ Accessibility audit and improvements
19. ✅ Code quality refactoring (split large files)
20. ✅ ASO and app store optimization

---

## 🎯 Quick Wins (Low Effort, High Impact)

1. **Fix CI runner** (5 min) - Immediate visibility into build status
2. **Add GitHub issue templates** (15 min) - Better bug reports and feature requests
3. **Create debug menu** (1 hour) - Easier testing and debugging
4. **Add release notes in-app** (already scaffolded) - Better user communication
5. **Audit and fix "Devotion Lock" → "Sacred Start"** (1 hour) - Brand consistency

---

## 📝 Documentation Gaps

Documents that should be created:
- `docs/TESTING_GUIDE.md` - How to test key flows manually
- `docs/MIGRATION_GUIDE.md` - Supabase migration procedures and rollbacks
- `docs/STREAK_RULES.md` - Explicit streak behavior documentation
- `docs/RUNBOOK.md` - Incident response and troubleshooting
- `docs/ERROR_HANDLING.md` - Error handling conventions and patterns
- `docs/PERFORMANCE.md` - Performance benchmarks and optimization guidelines
- `docs/ACCESSIBILITY.md` - Accessibility guidelines and testing checklist

---

## Conclusion

Sacred Start is a well-structured app with thoughtful design and solid technical foundation. The main issues fall into three categories:

1. **Launch Blockers**: Missing App Store requirements (privacy URLs, IAP config, FC entitlements)
2. **Technical Debt**: Lack of testing, monitoring, and error handling
3. **Feature Polish**: Incomplete features (voice chat, night mode, Sign in with Apple)

Addressing the critical issues will enable successful App Store launch. The medium and low priority items can be tackled iteratively post-launch to improve stability, user experience, and retention.

The codebase shows good architectural decisions (local-first, offline queues, proper separation of concerns) and excellent documentation. The main risk areas are lack of automated testing and production monitoring, which should be prioritized after launch.
