# Sacred Start Design System (ABY)

For design *why* and Mobbin rationale, see [DESIGN-PHILOSOPHY.md](../DESIGN-PHILOSOPHY.md).  
For shipped changes by version, see [CHANGELOG.md](../CHANGELOG.md).

Typography, color, and layout tokens live in code:

| Token file | Role |
|------------|------|
| `DevotionLock/Theme/ABYDesign.swift` | Spacing, radii, colors, headers |
| `DevotionLock/Theme/AppFont.swift` | `ABY.Font.*` — Inter Tight + Instrument Serif |
| `DevotionLock/Theme/AppTheme.swift` | Sanctuary palette, `DevotionTheme.sage` |

## Typography

- **UI:** Inter Tight (`ABY.Font.body`, `.headline`, `.caption`)
- **Editorial:** Instrument Serif (`ABY.Font.editorialTitle`, `.displayHero`)

## Backgrounds

- **Flat wash:** Home, Chaplain, Profile (`ABYFlatTabWashBackground`)
- **Full gradient:** Journal tab only (`MainTabShellBackground`)

## Component index

| Area | File |
|------|------|
| Chat / Chaplain | `Components/ABYChatComponents.swift` |
| Scripture cards | `Components/ChaplainScriptureComponents.swift` |
| Journal hub | `Components/ABYJournalComponents.swift` |
| Guided entry (shared) | `Views/JournalEntryViews.swift` (`GuidedJournalEntryView`) |
| Morning devotion | `Views/MorningFlowView.swift`, `Navigation/MorningFlowPlan.swift` |
| Sacred prayer | `Components/SacredPrayerComponents.swift` |
| Onboarding | `Components/OnboardingComponents.swift` |

## Mobbin references

Screens cite Mobbin URLs inline in Swift file headers (grep `mobbin.com`).
