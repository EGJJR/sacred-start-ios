# Sacred Start (iOS)

Morning sanctuary app for Christians — guided devotion, journaling, AI Chaplain, prayer community, and optional App Shield.

**Product name in marketing:** Sacred Start (bundle ID and Xcode target remain `DevotionLock` for now).

## Quick start

1. Open `devotionlock-mobile.xcodeproj` in Xcode 16+
2. Select the **DevotionLock** scheme and a physical device (required for App Shield / Family Controls)
3. Build and run

## Fresh clone setup

After `git clone`, the repo has all source, assets, and Supabase migrations. These steps are **not** in git and must be configured on each machine:

### Xcode (required to build on device)

1. Open the project → select the **DevotionLock** target → **Signing & Capabilities**
2. Choose your **Team** (Apple Developer account)
3. Ensure **Family Controls** is enabled for the App ID in [Apple Developer](https://developer.apple.com/account/resources/identifiers) — required for App Shield on physical devices
4. Release builds use `DevotionLock.family-controls.entitlements` (already wired in the project)

Simulator builds work without Family Controls; shield features need a real device + TestFlight for full testing.

### Supabase CLI (only if you deploy backend changes)

The hosted project already runs in production. Re-link locally when you need to push migrations or edge functions:

```bash
npx supabase login
npx supabase link --project-ref ygirplpbgxwvstnqxnrz
npx supabase db push          # apply migrations
./scripts/deploy-supabase.sh  # deploy edge functions
```

### Supabase secrets (hosted — not in this repo)

Confirm in [Supabase Dashboard](https://supabase.com/dashboard) → **Edge Functions → Secrets**:

- `DEEPSEEK_API_KEY` — required for Chaplain chat and insights

`SUPABASE_SERVICE_ROLE_KEY` is injected automatically by Supabase into edge functions; do not commit it.

Auth: **Authentication → Providers → Email** — keep **Confirm email** off so sign-up works immediately (see `supabase/README.md`).

### What `.gitignore` excludes (safe — rebuilds or re-links)

Build artifacts (`DerivedData/`), Xcode user settings (`xcuserdata/`), and local Supabase CLI cache (`supabase/.temp/`). None of that is needed to clone and build.

Full App Store checklist: [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md).

## Documentation

| Doc | Purpose |
|-----|---------|
| [PROJECT_MAP.md](PROJECT_MAP.md) | Codebase directory, what's implemented, what's left |
| [docs/PRODUCT_OVERVIEW.md](docs/PRODUCT_OVERVIEW.md) | Product features and positioning |
| [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md) | Pre–App Store manual checklist |

Marketing website lives in a separate repo/folder: `../sacred-start-web` (sibling to this project).
