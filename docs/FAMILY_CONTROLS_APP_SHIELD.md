# App Shield — Family Controls & Screen Time Setup

Reference for enabling **App shield** (Screen Time blocking) in Devotion Lock / Sacred Start on **TestFlight** and the **App Store**.

**Bundle ID:** `com.devotionlock.mobile`  
**Team ID (project):** `L4SCYKMRN5`

---

## How App Shield works in the app

When the user taps **Allow Screen Time access**, the app calls:

```swift
AuthorizationCenter.shared.requestAuthorization(for: .individual)
```

iOS then talks to Apple’s Screen Time **helper** (a system daemon). If that handshake fails, the user sees:

> **Couldn't communicate with a helper application**

That message is **not** a Supabase or journal bug. It means Screen Time permission was never granted.

Relevant code:

- `DevotionLock/Services/Shield/AppShieldManager.swift`
- `DevotionLock/Views/ShieldSettingsView.swift`

---

## Why TestFlight fails today (but local Debug may work)

The Xcode project uses **different entitlements** per configuration:

| Configuration | Entitlements file | Family Controls |
|---------------|-------------------|-----------------|
| **Debug** (local Xcode on device) | `DevotionLock/DevotionLock.family-controls.entitlements` | Yes |
| **Release** (TestFlight / App Store) | `DevotionLock/DevotionLock.entitlements` | **No** |

Apple provides two levels of Family Controls access:

1. **Development** — test on your own devices via Xcode Debug builds.
2. **Distribution** — required for **TestFlight** and **App Store** (uses distribution provisioning profiles).

Until **Family Controls Distribution** is approved **and** Release builds use the family-controls entitlements file, beta users will keep seeing the helper-application error. **Users cannot fix this in Settings.**

---

## Official Apple links

| Step | URL |
|------|-----|
| **Request Family Controls Distribution** (submit as Account Holder) | https://developer.apple.com/contact/request/family-controls-distribution |
| Apple guide — requesting the entitlement | https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement |
| Xcode — configuring Family Controls | https://developer.apple.com/documentation/xcode/configuring-family-controls |
| Identifiers (App IDs) | https://developer.apple.com/account/resources/identifiers/list |
| Provisioning profiles | https://developer.apple.com/account/resources/profiles/list |
| Capability request status | https://developer.apple.com/account/resources/capabilities/list |
| Capability requests (help) | https://developer.apple.com/help/account/capabilities/capability-requests |
| Developer support (if request stalls) | https://developer.apple.com/contact/ |
| Forums — Family Controls request thread | https://developer.apple.com/forums/thread/735888 |

### What to put in the distribution request

- **Bundle ID:** `com.devotionlock.mobile`
- **Use case:** Digital wellbeing / morning devotion — user selects apps to block via Screen Time until they complete their devotion.
- **Frameworks:** `FamilyControls`, `ManagedSettings` (Screen Time API).
- Devotion Lock’s main app target only (no Device Activity / Shield extensions in this repo at time of writing). If extensions are added later, **submit a separate request per extension bundle ID**.

Approval often takes **days to several weeks**. TestFlight cannot use shield without distribution approval.

---

## Part 1 — After Apple approves distribution

### Enable Family Controls on the App ID

1. Open [Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Select **`com.devotionlock.mobile`**.
3. Under **Capabilities**, enable **Family Controls** (should show **Family Controls (Distribution)** when approved).
4. Click **Save**.

### Refresh provisioning profiles

**Automatic signing (recommended):**

- Xcode updates profiles on the next archive. No manual step usually needed.

**Manual signing:**

1. [Profiles](https://developer.apple.com/account/resources/profiles/list) → your App Store / distribution profile for `com.devotionlock.mobile`.
2. Edit → ensure Family Controls is included → Generate → Download → double-click to install.

### Check approval status

1. [Capability Requests](https://developer.apple.com/account/resources/capabilities/list) → **Family Controls**.
2. Status should be **Assigned** when ready.
3. Confirm **Provisioning Support** lists distribution methods you need (App Store / TestFlight).

---

## Part 2 — Point Release at Family Controls entitlements (Xcode)

**Only after** distribution approval. Before approval, switching Release may cause signing failures.

### Steps in Xcode

1. Open `devotionlock-mobile.xcodeproj`.
2. Select the **project** (blue icon) → **TARGETS** → **DevotionLock** (not the widget).
3. **Build Settings** → search **Code Signing Entitlements**.
4. Set **Release** to:

   ```
   DevotionLock/DevotionLock.family-controls.entitlements
   ```

   **Debug** should already be the same path.

5. **Signing & Capabilities** tab:
   - Team: your Apple Developer team
   - **Automatically manage signing:** ON
   - **Family Controls** capability visible

6. **Product → Clean Build Folder** (⇧⌘K).

### Project file reference (for code review)

In `devotionlock-mobile.xcodeproj/project.pbxproj`:

- Debug: `CODE_SIGN_ENTITLEMENTS = DevotionLock/DevotionLock.family-controls.entitlements`
- Release (before fix): `CODE_SIGN_ENTITLEMENTS = DevotionLock/DevotionLock.entitlements`
- Release (after fix): `CODE_SIGN_ENTITLEMENTS = DevotionLock/DevotionLock.family-controls.entitlements`

Entitlements files:

- `DevotionLock/DevotionLock.entitlements` — app group only (no Family Controls)
- `DevotionLock/DevotionLock.family-controls.entitlements` — app group + `com.apple.developer.family-controls`

---

## Part 3 — Archive and upload to TestFlight

1. Scheme: **DevotionLock**.
2. Destination: **Any iOS Device (arm64)** (not Simulator).
3. Bump **Build** number if re-uploading (Target → General → Build).
4. **Product → Archive**.
5. Organizer → **Distribute App** → **App Store Connect** → **Upload**.
6. Wait for processing in [App Store Connect](https://appstoreconnect.apple.com) → **TestFlight**.

CI note: `.github/workflows/ios.yml` may sign Release with `DevotionLock.entitlements` — update that workflow when enabling Family Controls for distribution builds.

---

## Part 4 — Test on a physical iPhone

1. Install the **new** TestFlight build (old builds will still fail).
2. **Settings → Screen Time** → turn Screen Time **On**.
3. App → **You → App shield → Allow Screen Time access** → approve with Face ID / Touch ID.
4. **Choose what to shield** → select apps.
5. Complete a devotion → shields should clear (unless **Strict mode** is on).

**Simulator:** Family Controls / Screen Time authorization does not work reliably on Simulator. Always test on a real device.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Couldn't communicate with a helper application | Release build without distribution entitlement; or approval not granted yet |
| Works in Xcode Debug, fails on TestFlight | Debug has `family-controls.entitlements`; Release does not |
| Archive / signing fails after switching entitlements | Distribution not approved, or App ID not saved with Family Controls |
| Authorization succeeds but nothing blocks | No apps selected in picker; Screen Time off; devotion already completed today |
| QUIC / `nw_read_request_report` logs in console | Normal iOS network noise when talking to Supabase; unrelated to Screen Time |

### If the distribution request sits for weeks

- Check [Capability Requests](https://developer.apple.com/account/resources/capabilities/list).
- File a support request: https://developer.apple.com/contact/ (include Team ID and bundle ID).
- See forums: https://developer.apple.com/forums/thread/735888

---

## Optional: clearer in-app error copy

`AppShieldManager.friendlyMessage` currently surfaces Apple’s raw error. Consider detecting `"helper application"` and showing:

> App shield isn’t available in this build yet. Install an updated version from TestFlight after Screen Time support is enabled for this app.

---

## Related docs

- [LAUNCH_CHECKLIST.md](./LAUNCH_CHECKLIST.md) — high-level launch checklist (entitlements bullet points)
- [README.md](../README.md) — notes on Release vs family-controls entitlements

---

*Last updated: June 2026 — review after Apple Family Controls Distribution approval and before next TestFlight ship.*
