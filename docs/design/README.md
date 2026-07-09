# Sacred Start — Design & System Documentation

Central home for product design, design philosophy, changelog, and system architecture.  
**Code is the source of truth for behavior; these docs explain why.**

---

## Start here

| Document | Purpose |
|----------|---------|
| **[DESIGN-PHILOSOPHY.md](DESIGN-PHILOSOPHY.md)** | Design thought process — ABY aesthetic, Mobbin patterns, chat/journal/recap rules, what we avoid |
| **[APPLE-DESIGN-AUDIT.md](APPLE-DESIGN-AUDIT.md)** | Audit vs [Apple Design skill](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md) — gaps, ABY vs Clean differentiation |
| **[CHANGELOG.md](CHANGELOG.md)** | Full product changelog by area (Design, Chaplain, Journal, Bible, Navigation, Backend) |

---

## Structure

| Folder | Purpose |
|--------|---------|
| [system-design/](system-design/) | Architecture, seams, data flows, ADR-style decisions |
| [design-system/](design-system/) | Typography, color, components, Mobbin references (token index) |
| [improvements/](improvements/) | Backlog ideas, psychology audits, suggested enhancements |

---

## Design system (code)

| Token file | Role |
|------------|------|
| `DevotionLock/Theme/ABYDesign.swift` | Spacing, radii, colors, backgrounds, headers |
| `DevotionLock/Theme/AppFont.swift` | Inter Tight + Instrument Serif |
| `DevotionLock/Theme/AppTheme.swift` | Sanctuary palette, springs, `DevotionTheme.sage` |

**Background rule of thumb:** flat tab wash on browse surfaces (Home, Chaplain, Profile, Bible); full sanctuary gradient on Journal tab and immersive flows only. See [DESIGN-PHILOSOPHY.md](DESIGN-PHILOSOPHY.md#2-flat-over-gradient-stacking).

---

## Related docs (repo root)

| Doc | Location |
|-----|----------|
| Product overview | [../PRODUCT_OVERVIEW.md](../PRODUCT_OVERVIEW.md) |
| Launch checklist | [../LAUNCH_CHECKLIST.md](../LAUNCH_CHECKLIST.md) |
| Codebase map | [../../PROJECT_MAP.md](../../PROJECT_MAP.md) |

---

## Conventions

- Version docs when they describe shipped behavior (note app version in [CHANGELOG.md](CHANGELOG.md)).
- Prefer diagrams (mermaid) + tables over long prose in system-design; philosophy doc carries narrative.
- Mobbin URLs live in Swift file headers — grep `mobbin.com` in `DevotionLock/` for screen-level refs.
- Link GitHub issues for tracked work; use [improvements/backlog.md](improvements/backlog.md) for ideas not yet filed.
