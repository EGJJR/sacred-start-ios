# Family Controls & App Shield — Setup Guide

How to fix **"Couldn't communicate with a helper application"** on TestFlight/production builds and ship App Shield (Screen Time blocking) to users.

---

## Why beta users see the helper error

When users tap **Allow Screen Time access**, the app calls:

```swift
AuthorizationCenter.shared.requestAuthorization(for: .individual)
```

iOS talks to a **system Screen Time helper**. The error **"Couldn't communicate with a helper application"** means that handshake failed — the app never received Screen Time permission.

### Root cause in this project

| Build | `CODE_SIGN_ENTITLEMENTS` | Family Controls |
|-------|--------------------------|-----------------|
| **Debug** (local Xcode) | `DevotionLock/DevotionLock.family-controls.entitlements` | Yes |
| **Release** (TestFlight/App Store) | `DevotionLock/DevotionLock.entitlements` | **No** |

Release builds intentionally omit Family Controls until Apple approves **Family Controls Distribution**. TestFlight uses Release signing, so shield auth fails for beta users.

**This is not fixable by users in Settings** — it requires Apple approval + a new build.

Related code:
- `DevotionLock/Services/Shield/AppShieldManager.swift` — `requestAuthorization()`
- `DevotionLock/Views/ShieldSettingsView.swift` — "Allow Screen Time access" button
- `DevotionLock/DevotionLock.family-controls.entitlements` — includes `com.apple.developer.family-controls`
- `DevotionLock/DevotionLock.entitlements` — app groups only (Release today)
- `devotionlock-mobile.xcodeproj/project.pbxproj` — Debug vs Release entitlements lines

---

## Prerequisites

- [ ] Paid **Apple Developer Program** membership (Account Holder can submit entitlement requests)
- [ ] App record in **App Store Connect** (need Apple ID / bundle ID context for the form)
- [ ] Bundle ID: **`com.devotionlock.mobile`**
- [ ] Team ID in project: **L4SCYKMRN5**

---

## Step 1 — Request Family Controls Distribution

**Must be done by Account Holder** (or whoever Apple allows for entitlement requests).

### Official links

| Resource | URL |
|----------|-----|
| **Distribution request form** | https://developer.apple.com/contact/request/family-controls-distribution |
| **Apple documentation** | https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement |
| **Xcode configuration** | https://developer.apple.com/documentation/xcode/configuring-family-controls |
| **Check request status** | https://developer.apple.com/account/resources/capabilities/list |
| **Capability requests help** | https://developer.apple.com/help/account/capabilities/capability-requests |
| **Identifiers (App IDs)** | https://developer.apple.com/account/resources/identifiers/list |
| **Profiles** | https://developer.apple.com/account/resources/profiles/list |
| **App Store Connect** | https://appstoreconnect.apple.com |
| **Support (if stuck weeks)** | https://developer.apple.com/contact/ |
| **Forums discussion** | https://developer.apple.com/forums/thread/735888 |

### Form tips

- Bundle ID: `com.devotionlock.mobile`
- Explain: Sacred Start / Devotion Lock uses Screen Time to block user-selected apps until morning devotion completes
- Frameworks: `FamilyControls`, `ManagedSettings`
- Devotion Lock uses **main app only** (no Device Activity / Shield extensions) → **one** request should suffice
- Approval often takes **days to several weeks**
- **TestFlight cannot use shield without distribution approval** (development entitlement is not enough)

---

## Step 2 — Enable capability on App ID (after approval)

1. Open [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Select **`com.devotionlock.mobile`**
3. Enable **Family Controls** (should show **Family Controls (Distribution)** after approval)
4. **Save**

### Refresh provisioning

**Automatic signing (recommended):** Xcode updates profiles on next archive — usually nothing manual needed.

**Manual signing:**
1. [Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Edit App Store / distribution profile for `com.devotionlock.mobile`
3. Ensure Family Controls is enabled → Generate → Download → install

---

## Step 3 — Point Release at Family Controls entitlements (Xcode)

**Only after Apple approves distribution.** Before approval, Release builds may fail to sign with this file.

### Via Build Settings (recommended)

1. Open `devotionlock-mobile.xcodeproj`
2. Project navigator → blue **project** icon
3. **TARGETS** → **DevotionLock** (not widget)
4. **Build Settings** → search `Code Signing Entitlements`
5. Set **Release** to:

   ```
   DevotionLock/DevotionLock.family-controls.entitlements
   ```

   (Debug should already use this path.)

6. **Product → Clean Build Folder** (⇧⌘K)

### Via Signing & Capabilities

1. Target **DevotionLock** → **Signing & Capabilities**
2. Confirm **Family Controls** capability is present
3. Team: your Apple team
4. **Automatically manage signing**: ON

### project.pbxproj reference

```
Debug:   CODE_SIGN_ENTITLEMENTS = DevotionLock/DevotionLock.family-controls.entitlements
Release: CODE_SIGN_ENTITLEMENTS = DevotionLock/DevotionLock.entitlements  ← change after approval
```

Also tracked in `docs/LAUNCH_CHECKLIST.md` (Apple Developer / entitlements section).

---

## Step 4 — Archive & upload TestFlight

1. Scheme: **DevotionLock**
2. Destination: **Any iOS Device (arm64)** (not Simulator)
3. Bump **Build** number if re-uploading (General tab; was `2` at time of writing)
4. **Product → Archive**
5. Organizer → **Distribute App** → **App Store Connect** → **Upload**
6. Wait for processing in App Store Connect → **TestFlight**

---

## Step 5 — Test on a physical iPhone

1. Install the **new** TestFlight build (not an older build)
2. **Settings → Screen Time** → ensure Screen Time is **On**
3. App: **You → App shield → Allow Screen Time access**
4. Approve Face ID / Touch ID
5. **Choose what to shield** → pick apps
6. Complete devotion → verify apps unlock

**Simulator does not support Family Controls.**

---

## Checklist

| Step | Done when |
|------|-----------|
| Distribution request submitted | Form submitted at Apple link above |
| Apple approved | Capability Requests shows **Assigned** for Family Controls |
| App ID updated | Identifiers → Family Controls enabled |
| Release entitlements switched | Build Settings → Release uses `family-controls` entitlements |
| New build on TestFlight | App Store Connect shows new build |
| Shield works on device | No "helper application" error; picker works |

---

## If signing / archive fails

| Error | Likely cause |
|-------|----------------|
| Provisioning profile doesn't include entitlement | Distribution not approved or App ID not saved |
| Entitlement not allowed | Release still on plain entitlements, or approval not on team |

---

## Optional UX improvement (not yet implemented)

In `AppShieldManager.friendlyMessage(for:)`, detect `"helper application"` and show a clearer message, e.g.:

> App shield isn't available in this build yet. Screen Time requires an app update with Apple's Family Controls permission.

---

## Other session fixes (related context)

These were fixed in the same development period but are separate from entitlements:

1. **Streak / prayer wall flickering when signed in** — `DemoDataCleaner` ran on every token refresh and wiped local data. Fixed with one-shot guard + only clear on sign-in. Files: `DemoDataCleaner.swift`, `AuthManager.swift`.

2. **Launch crash (`StreakManager.shared` deadlock)** — `SharedDataSync` called other singletons during `init`. Fixed with deferred `scheduleRefresh()`. File: `SharedDataSync.swift`.

3. **Blank Settings legal screens** — likely unresolved `NavigationLink` in `AboutView`; fix not yet implemented. Files: `ProfileView.swift`, `AboutView.swift`, `LegalDocumentViews.swift`.

4. **Profile photo not showing on Settings** — local cache + observation fix. Files: `AuthManager.swift`, `AvatarLocalCache.swift`, `ProfileView.swift`, `SettingsComponents.swift`.

5. **QUIC / `nw_` console logs** — benign iOS network noise during Supabase calls; not the shield error.

---

## CI note

`.github/workflows/ios.yml` uses `DevotionLock/DevotionLock.entitlements` for CI builds (no Family Controls). Local Debug uses family-controls entitlements.
