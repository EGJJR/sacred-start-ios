# Devotion Lock — App Store Launch Checklist

Use this before submitting v1 to App Store Connect or TestFlight.

## Supabase (production)

- [ ] Apply all migrations in order (`supabase/migrations/*.sql`), including `20260607130000_sync_extensions.sql`
- [ ] Deploy edge functions: `chaplain-chat`, `generate-insight`, `delete-account`
- [ ] Set `DEEPSEEK_API_KEY` in Supabase Edge Function secrets
- [ ] Auth → Email: **Confirm email OFF** so sign-up works immediately
- [ ] Test account deletion end-to-end (Profile → Edit account → Delete account)

Deploy via CLI (from repo root):

```bash
npx supabase login
npx supabase link --project-ref ygirplpbgxwvstnqxnrz
npx supabase db push
./scripts/deploy-supabase.sh
```

## In-App Purchases (App Store Connect)

- [ ] Create subscription group **Devotion Lock Premium**
- [ ] Add products matching the app:
  - `com.devotionlock.mobile.premium.weekly.v2` ($3.99/wk)
  - `com.devotionlock.mobile.premium.monthly.v2` ($11.99/mo)
  - `com.devotionlock.mobile.premium.annual.v2` ($49.99/yr)
- [ ] Add **5-day free trial** introductory offer on the annual plan (matches `DevotionLock.storekit`)
- [ ] Link IAP to the app record; add localizations and pricing
- [ ] Sandbox test: start trial → full access → cancel before charge → trial expiry → paywall returns
- [ ] Test **Restore Purchases** on paywall

## Apple Developer / entitlements

- [ ] Paid Apple Developer Program membership active
- [ ] **Family Controls** capability enabled for the App ID (required for App Shield)
- [ ] **Family Controls Distribution** approved by Apple (required for TestFlight/App Store builds with shield)
- [ ] Release entitlements: `DevotionLock.entitlements` until FC distribution is approved; then switch Release back to `DevotionLock.family-controls.entitlements`
- [ ] Debug builds may still use `DevotionLock.family-controls.entitlements` for local shield testing
- [ ] Test shield authorization on a **physical device** via TestFlight after FC distribution build is uploaded (not Simulator)

## App Store Connect metadata

- [ ] **Privacy Policy URL** (public, even though in-app legal exists)
- [ ] **Terms of Use URL** (or standard Apple EULA + custom terms link)
- [ ] Privacy nutrition labels: email, user-generated content (journal, prayers, circles), product interaction, AI processing via your backend
- [ ] Age rating: likely **12+** (user-generated prayer circle content)
- [ ] Screenshots and description state Chaplain is **AI-powered**, not human clergy
- [ ] Subscription auto-renew disclosure visible in app (paywall includes this)
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption = NO` (set in `AppFontInfo.plist`)

## Pre-submit smoke test (device)

- [ ] Fresh install → sign up → onboarding → paywall → start 5-day trial
- [ ] Morning devotion completes and syncs
- [ ] Chaplain chat streams a response
- [ ] Prayer wall + circles create/sync
- [ ] App shield authorizes and blocks selected apps
- [ ] Sign out (Profile → Edit account → Sign out)
- [ ] Delete account removes remote data
- [ ] Background/foreground: no memory kill after 15+ minutes normal use

## Local build hygiene

- [ ] Keep **10+ GB free** on Mac before archiving (DerivedData fills quickly)
- [ ] Quit Xcode before terminal `xcodebuild` if packages fail to resolve
- [ ] Archive with **Release** configuration on physical device destination
