# Apple Design Skill — App Audit

**Branch:** `audit/apple-design-skill`  
**Skill source:** [emilkowalski/skills — apple-design](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md)  
**Date:** 2026-07-09  
**Scope:** Entire iOS app (ABY production system + Clean experiment on this working tree)

This document reviews Sacred Start against Apple’s fluid-interface principles (WWDC *Designing Fluid Interfaces* and related talks, as distilled in the skill). It is a **gap analysis and differentiation map**, not an implementation plan.

---

## Executive summary

Sacred Start already aligns well with Apple’s **foundational design principles** (purpose, agency, simplicity, craft) via `docs/design/DESIGN-PHILOSOPHY.md`. Motion and materials are **partially** Apple-like: shared springs, press-scale feedback, glass chrome, and semantic haptics exist — but the app is still mostly **scripted animation**, not **gesture-driven physics**.

| Layer | Verdict vs Apple Design skill |
|-------|-------------------------------|
| **Philosophy / product tone** | Strong match (purpose, agency, restraint, delight-as-outcome) |
| **Response & press feedback** | Good on primary CTAs; incomplete coverage |
| **Springs as default motion** | Present, but often under-damped vs Apple’s critically damped default |
| **Gesture → velocity → interruptible springs** | Largely missing (sheets rely on system; almost no custom drag physics) |
| **Materials & depth** | Good on ABY nav/composers; Clean experiment regresses to opaque chrome |
| **Reduced motion / transparency / contrast** | Partial (`accessibilityReduceMotion` in ~11 places; no reduce-transparency path) |
| **Typography (optical sizing, Dynamic Type)** | Custom faces without size-aware tracking tables or Dynamic Type scaling |
| **Clean experiment vs ABY** | Clean is a visual simplification fork; it does **not** move the app closer to Apple fluid-interaction craft |

**Bottom line:** The skill would change **interaction physics and accessibility completeness** more than visual branding. ABY is closer to Apple’s material/motion language than Clean; Clean is closer to a minimal product aesthetic but farther from Apple’s translucent, interruptible UI model.

---

## What the skill asks for (quick map)

The skill’s through-line:

> Motion starts from the current on-screen value, inherits velocity, projects momentum, and can be grabbed and reversed at any instant.

| # | Principle | Concrete expectation |
|---|-----------|----------------------|
| 1 | Response | Feedback on touch-down; kill latency on the input path |
| 2 | Direct manipulation | 1:1 finger tracking; respect grab offset |
| 3 | Interruptibility | Never lock input mid-transition; animate from presentation value |
| 4 | Springs over keyframes | Critically damped default (`damping 1.0`, `response 0.3–0.4`); bounce only after momentum |
| 5 | Velocity handoff | Release velocity becomes spring initial velocity |
| 6 | Momentum projection | Snap to projected endpoint, not release point |
| 7 | Spatial consistency | Enter/exit same path; origin-anchored menus |
| 8 | Gesture hinting | Intermediate frames telegraph the outcome |
| 9 | Rubber-banding | Soft boundaries, progressive resistance |
| 10 | Gesture details | Hysteresis, parallel recognizers, cancel-by-drag-away |
| 11 | Frame smoothness | Compositor props; avoid strobing |
| 12 | Materials & depth | Translucent chrome; content scrolls under; no light-on-light glass stack |
| 13 | Multimodal feedback | Visual + haptic (+ sound) same frame; utility over noise |
| 14 | Accessibility | Reduced motion → cross-fade; reduced transparency → solid; more contrast → borders |
| 15 | Typography | Size-specific tracking; Dynamic Type; prefer system font unless justified |
| 16 | Eight principles | Purpose, agency, responsibility, familiarity, flexibility, simplicity, craft, delight |
| 17 | Process | Interactive prototypes; motion reviewed with visuals |

---

## What is already in the app

### Two visual systems in this tree

| | **ABY (production)** | **Clean experiment** (`CleanExperiment.isEnabled`) |
|--|----------------------|-----------------------------------------------------|
| Tokens | `ABYDesign.swift`, `AppFont.swift`, `AppTheme.swift` | `CleanDesign.swift`, Open Runde, Solar Duotone |
| Type | Inter Tight + Instrument Serif | Open Runde only (serif swapped out when Clean is on) |
| Nav | Glass pill + Sacred Orb (`BottomNavigationBar`, `ABYGlassBarBackground`) | Opaque white capsule (`CleanBottomNavigationBar`) |
| Home | Ritual / rhythm-forward `HomeView` | Solace-style 2×2 `CleanHomeView` |
| Palette | Soft washes, mood pills, editorial cards | Single sacred-green accent, warm off-white field |
| Docs | `DESIGN-PHILOSOPHY.md`, design-system overview | `Views/Clean/README.md` |

Clean is a **brand/layout experiment**, not an Apple-fluidity upgrade. When enabled, `AppFont` routes all `ABY.Font` calls through Open Runde, so the experiment cascades into Chaplain, Journal, and Profile without rewriting every screen.

### Motion infrastructure that already exists

```23:30:DevotionLock/Theme/AppTheme.swift
    static let springSnappy = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let springGentle = Animation.spring(response: 0.55, dampingFraction: 0.86)
    /// Speed-dial menus (Pangea / Airwallex / Jobber pattern on Mobbin).
    static let springMenu = Animation.spring(response: 0.44, dampingFraction: 0.78)
    /// Staggered pill reveal from nav orb (WHOOP / Pangea fan-out).
    static let springMenuReveal = Animation.spring(response: 0.46, dampingFraction: 0.74)
    /// Collapse pills back into orb on dismiss.
    static let springMenuCollapse = Animation.spring(response: 0.34, dampingFraction: 0.88)
```

| Asset | Approx. usage | Apple skill alignment |
|-------|---------------|------------------------|
| `ScaleButtonStyle` (scale `0.97` on press) | ~86 call sites | Matches skill §1 press feedback |
| `AppTheme.spring*` | Widespread | Springs exist; damping mostly **&lt; 1.0** (skill wants `1.0` default) |
| `DevotionHaptics` | ~102 call sites | Matches skill §13 utility intent (philosophy: soft / success / avoid chip noise) |
| `.ultraThinMaterial` / glass bars | ~27 material uses | Matches skill §12 for ABY chrome |
| `presentationDetents` | ~21 sheets | System sheets give interruptibility “for free” |
| `accessibilityReduceMotion` | ~11 files | Partial §14 |
| Custom `DragGesture` | **1** (press highlight on compose pill) | Almost no §2–§6 custom physics |
| `repeatForever` ambient loops | ~36 | Conflicts with skill §14 (vestibular / looping motion) unless gated |

### Philosophy overlap (skill §16)

Sacred Start’s written principles already map cleanly:

| Apple principle | Sacred Start equivalent |
|-----------------|-------------------------|
| Purpose | Morning sanctuary, one dominant action per screen |
| Agency | Keep-as-spoken default; skippable depth; pray *or* reflect |
| Responsibility | Chaplain disclaimer; ephemeral polish; no auto-rewrite of prayer |
| Familiarity | Mobbin-informed patterns (Gemini chat, ABY journal, system sheets) |
| Flexibility | Feature flags; sanctuary appearance; Clean toggle (dev) |
| Simplicity (not minimalism) | Flat wash over gradient stacking; chips only when empty |
| Craft | Tokenized spacing/radius/type; glass weight rules; changelog discipline |
| Delight | Completion / wrapped beats / soft haptics — outcome of ritual, not confetti-first |

The skill would **reinforce** this philosophy; it would not replace it.

---

## Principle-by-principle audit

Scores: **Aligned** · **Partial** · **Gap** · **Conflict**

### 1. Response — kill latency → **Partial**

**There:** `ScaleButtonStyle` highlights on press (`isPressed`), not only on release — matches Apple’s “feedback on pointer-down.” Compose pill in Chaplain uses a zero-distance `DragGesture` to drive press state.

**Missing:** Not every interactive control uses press feedback (Clean tab bar uses `.buttonStyle(.plain)` with no scale). No systematic audit of artificial delays / debounce on the input path. Portal / onboarding transitions can still feel “wait then animate” rather than continuous.

**Diff vs skill:** Skill treats latency as the foundation; we treat springs + scale as polish on discrete taps.

---

### 2–3. Direct manipulation & interruptibility → **Gap**

**There:** System sheets/detents inherit UIKit interruptibility. Tab selection and most UI are discrete state flips with `withAnimation`.

**Missing:** No custom drawers/carousels that track 1:1 with the finger, respect grab offset, or re-target from the live presentation value. `ChaplainPortalTransition` is a timed bloom sequence — beautiful, but not grab-and-reverse.

**Diff vs skill:** Apple’s “single most important principle” is interruptibility. Our signature transitions are **authored timelines**, closer to keyframe storytelling than fluid interfaces.

---

### 4. Behavior over animation — springs → **Partial / mild Conflict**

**There:** Shared spring tokens; philosophy doc names snappy vs gentle springs.

**Diff vs Apple defaults:**

| Token | Our damping | Skill default |
|-------|-------------|---------------|
| `springSnappy` | `0.82` | `1.0` critically damped for most UI |
| `springGentle` | `0.86` | `1.0` |
| Menu reveal/collapse | `0.74`–`0.88` | Bounce only after flick momentum |

We use **slight bounce as the house style**. Apple reserves under-damping for momentum-driven gestures. Result: menus and tab chips can feel “springy” even when the user only tapped.

Also: many ambient backgrounds use fixed-duration `easeInOut.repeatForever` (8–10s loops) — skill §4 / §14 prefer springs for interactive motion and discourage slow looping oscillations.

---

### 5–6. Velocity handoff & momentum projection → **Gap**

**There:** None found for custom gestures. Story pager (`MorningWrappedView`) advances by tap/CTA with haptic, not flick-projected pages.

**Diff vs skill:** This is the largest technical gap. Implementing Apple-like sheets/carousels would require velocity history, projection (`v/1000 * d/(1-d)`), and spring re-target — none of which exist as shared utilities today.

---

### 7–8. Spatial consistency & gesture hinting → **Partial**

**There:** Onboarding step-out / step-in easing; portal bloom suggests “entering sanctuary”; Sacred Orb menu fan-out is spatially anchored to the orb.

**Missing:** No formal rule that every custom overlay exits the way it entered. Some full-screen covers may feel like hard cuts relative to the trigger.

---

### 9–10. Rubber-banding & gesture details → **Gap** (custom) / **Aligned** (system scroll)

**There:** Native `ScrollView` rubber-banding. Sheet detents.

**Missing:** Custom rubber-band helper; parallel gesture disambiguation for app-owned drag UIs; hysteresis documented as a shared constant (~10pt).

---

### 11. Frame-level smoothness → **Partial**

**There:** Mostly `transform`/`opacity` via SwiftUI springs and scale. Canvas confetti / waveforms are intentional special cases.

**Risk:** Heavy blur + mesh + forever animations on low-end devices; portal material opacity animations. No shared “compositor-only” motion guideline in code.

---

### 12. Materials & depth → **Aligned (ABY)** · **Conflict (Clean)**

**ABY — aligned:**

- `ABYGlassBarBackground` = `.ultraThinMaterial` + palette fill + hairline stroke (light catching the edge).
- Bottom nav comments explicitly forbid glass-on-glass (iOS 26 `GlassEffectContainer` path).
- Content can scroll under floating chrome; philosophy: glass separates nav from content, not “glass everything.”

**Clean — conflict with skill §12:**

```25:28:DevotionLock/Components/CleanBottomNavigationBar.swift
            .background(CleanDesign.Color.surface)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
```

Opaque white pill + drop shadow. Skill wants translucent chrome with content scrolling underneath and material weight encoding hierarchy. Clean trades Apple material language for Solace-like solidity.

**Also missing:** `accessibilityReduceTransparency` → solidify materials (skill §14). No hits in the codebase.

---

### 13. Multimodal feedback → **Partial / Aligned intent**

**There:** `DevotionHaptics` with light / soft / medium / success; philosophy limits haptic noise; wrapped page turns use soft ticks; completion uses success.

**Missing:** No systematic pairing of haptic with the *same frame* as visual snap for custom gestures (because custom gesture snaps barely exist). No `sensoryFeedback` API usage observed. Sound is not part of the delight system.

---

### 14. Reduced motion & accessibility → **Partial**

**There:** `@Environment(\.accessibilityReduceMotion)` in prayer, Chaplain presence, portal, ambient AI, journal hub — good islands of care.

**Gaps:**

| Signal | Status |
|--------|--------|
| `accessibilityReduceMotion` | Partial coverage; ambient `repeatForever` loops often ungated |
| `accessibilityReduceTransparency` | **Absent** |
| `accessibilityDifferentiateWithoutColor` / more contrast | Not systematized for glass surfaces |
| Dynamic Type | Custom `UIFont(name:size:)` / fixed pt sizes; almost no `@ScaledMetric` / text-style relative fonts |

Skill: reduced motion should replace slides/springs with short cross-fades — we sometimes skip animation, sometimes leave loops running.

---

### 15. Typography → **Partial / mild Conflict**

**ABY:** Inter Tight + Instrument Serif — justified by editorial “sanctuary” brand (skill allows override “with a reason”). Tracking appears (~47 `.tracking` uses) but is **ad hoc** (often `0.6`–`0.8` on small labels), not a size→tracking curve. Large display type rarely uses negative tracking as Apple recommends.

**Clean:** Open Runde geometric rounded — farther from SF’s optical tables. Three sizes + metric — simpler hierarchy, but still fixed pt, not Dynamic Type.

**Skill default:** Prefer system font for optical sizing / tracking tables. Both ABY and Clean choose custom faces; ABY’s dual-face system is closer to Apple’s “display vs text” split, Clean collapses to one face.

---

### 16. Eight principles → **Aligned**

Documented and largely practiced. Highest residual risks:

- **Familiarity:** Clean nav labels (Home / Journal / Chat / Profile) are more generic than skill’s “specific labels” tip; ABY orb micro-labels are more contextual.
- **Flexibility:** Night mode intentionally incomplete (`nightGradientEnabled = false`) — honest, but unfinished.
- **Craft:** Dual systems (ABY + Clean) increase inconsistency risk until one wins.

---

### 17. Process → **Partial**

**There:** Design tour (`DesignTourView`), Mobbin citations in file headers, philosophy + changelog, Clean flag for A/B feel.

**Missing relative to skill:** Interactive physics prototypes (velocity, rubber-band) as a first-class bar before shipping gesture UIs; slow-motion motion review checklist.

---

## Differentiation matrix — skill vs ABY vs Clean

| Concern | Apple Design skill | ABY (current production) | Clean experiment |
|---------|--------------------|--------------------------|------------------|
| Primary metaphor | Physical, interruptible UI | Morning sanctuary / editorial cards | Quiet productivity shell |
| Motion model | Gesture → velocity → spring | Tap → `withAnimation(spring*)` | Same springs; less glass motion |
| Default spring | Critically damped | Slightly bouncy house springs | Inherits ABY springs |
| Chrome | Translucent materials | Glass pills / composers | Opaque white pill |
| Type | System-first, size-aware tracking | Inter Tight + Serif, fixed sizes | Open Runde, 2–3 sizes |
| Icons | SF Symbol familiarity | SF Symbols + custom orb | Solar Duotone (brand-forward) |
| Feedback | Press-down + haptic on commit | ScaleButtonStyle + DevotionHaptics | Tabs: selection only, no scale |
| Accessibility triad | Motion / transparency / contrast | Motion islands only | Same gaps; opaque chrome accidentally helps transparency |
| One action / screen | Simplicity principle | Explicit philosophy rule | 2×2 grid — more parallel actions on Home |
| Docs | Skill as craft checklist | `DESIGN-PHILOSOPHY.md` | `Views/Clean/README.md` |

### What would change if we “followed the skill” without abandoning Sacred Start

**Keep (already Sacred Start / Apple-aligned):**

- One primary beat per screen; pastoral agency; presence honesty
- Glass as structural chrome (ABY), not decoration
- Semantic haptics; press-scale on CTAs
- System sheets/detents

**Adjust (skill-driven refinements):**

1. Retune `AppTheme` springs toward critically damped defaults; reserve bounce for flick-driven UI only  
2. Gate all `repeatForever` ambient motion on `accessibilityReduceMotion`  
3. Add reduce-transparency solid fills for glass bars/cards  
4. Introduce size-based tracking tokens (tighten display, body ≈ 0)  
5. Wire Dynamic Type / `@ScaledMetric` into `ABY.Font` / `CleanFont`  
6. Apply `ScaleButtonStyle` (or equivalent) to Clean tab buttons  

**Build only if we add custom gesture surfaces:**

7. Shared velocity tracker + momentum projection + rubber-band helpers  
8. Interruptible portal / menu transitions (grab mid-flight)  
9. Story pager flick with projected page snap  

**Do not confuse with Clean:**

- Switching to Open Runde / opaque nav / Solar icons is **orthogonal** to Apple fluid design  
- Clean may still be the right product bet; it is not the skill’s checklist

---

## Hotspots by surface

| Surface | Apple-skill notes |
|---------|-------------------|
| **Tab bar (ABY)** | Strong materials; press + haptics; iOS 26 glass path thoughtful | 
| **Tab bar (Clean)** | Opaque; no press scale; farther from §12 |
| **Chaplain chat** | Flat canvas + composer; press on compose pill; portal is non-interruptible theater |
| **Morning Wrapped** | Ceremony over physics; haptic page turns; opportunity for flick projection |
| **Sacred prayer / breath** | Reduce-motion aware in places; breath loops need full gating |
| **Journal hub sheets** | System detents; row press style good |
| **Onboarding / paywall** | Authored fades; spatial consistency OK; not gesture-driven |
| **Home (ABY)** | One CTA philosophy aligns with §16 simplicity |
| **Home (Clean)** | Grid of equal cards — skill “simplicity” vs product experiment tradeoff |

---

## Evidence snapshot (codebase counts, 2026-07-09)

| Signal | Count (approx.) |
|--------|-----------------|
| `ScaleButtonStyle` usages | 86 |
| `DevotionHaptics` call sites | 102 |
| Material fills (ultra/thin/regular) | 27 |
| `presentationDetents` | 21 |
| `accessibilityReduceMotion` references | 11 |
| Custom `DragGesture` | 1 |
| `repeatForever` animations | 36 |
| `.tracking(` usages | 47 |
| `accessibilityReduceTransparency` | 0 |

---

## Recommended review order (for humans)

1. Read skill §§1–6 and §§12–15 (response, interruptibility, springs, materials, a11y, type).  
2. Compare side-by-side: ABY tab bar vs Clean tab bar (materials).  
3. Play Chaplain portal + Sacred Orb menu — ask “can I reverse mid-flight?”  
4. Enable Reduce Motion / Reduce Transparency in Settings — note what still loops or stays glassy.  
5. Bump Dynamic Type to xxxLarge — note layout/type breakage.  
6. Decide: skill workstreams are **physics + a11y + spring retune**, independent of whether Clean ships.

---

## Related docs

- Skill: https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md  
- [DESIGN-PHILOSOPHY.md](./DESIGN-PHILOSOPHY.md) — Sacred Start interaction & visual rules  
- [design-system/overview.md](./design-system/overview.md) — token index  
- [Views/Clean/README.md](../../DevotionLock/Views/Clean/README.md) — Clean experiment scope  
- Code: `AppTheme.swift`, `ABYDesign.swift`, `CleanDesign.swift`, `BottomNavigationBar.swift`, `CleanBottomNavigationBar.swift`, `DelightComponents.swift`, `SharedComponents.swift` (`ScaleButtonStyle`)

---

## Changelog for this audit branch

- Created branch `audit/apple-design-skill` from the Clean-experiment working tree.  
- Added this document only (no behavior changes).  
- Working tree still contains uncommitted Clean experiment assets/code from `experiment/clean-home-design`; they are in scope for comparison but were not authored as part of this audit.
