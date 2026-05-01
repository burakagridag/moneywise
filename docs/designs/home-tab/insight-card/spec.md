# Insight Card — Component Spec

**Component:** InsightCard
**Epic:** Epic 8A — Home Tab Redesign
**Related story:** EPIC8A-UX
**ADR reference:** ADR-011-insight-provider-interface.md

---

## Purpose

Display a single rule-based observation from the InsightEngine. Multiple InsightCards are stacked vertically under the "This week" section header. Each card is a self-contained unit with an icon, title, and subtitle. Cards may or may not be tappable.

---

## Layout

```
┌────────────────────────────────────────────┐  radius: 14dp, border 1dp
│  ┌──────┐  [Title text — 1 line ellipsis]  │  12dp top/bottom padding
│  │ icon │  [Subtitle — 1 line ellipsis]    │  14dp left/right padding
│  └──────┘                                  │
└────────────────────────────────────────────┘
margin: 0 16dp, 8dp bottom between cards
```

- Icon container: 36×36 dp, 10dp border radius
- Icon: 18×18 dp SVG/Lucide icon, centered
- Gap between icon and text column: 12dp
- Text column: flex, min-width 0 (to allow ellipsis)
- Title: 1 line, overflow ellipsis
- Subtitle: 1 line, overflow ellipsis, 2dp below title

---

## Content Mapping by Insight Severity (from ADR-011)

### Severity: warning
- Icon background (light): amber-100 tint = `rgba(255,167,38,0.15)` (based on `AppColors.warning` #FFA726)
- Icon background (dark): deep amber = `rgba(255,167,38,0.20)`
- Icon stroke color (light): `#C2410C` (dark amber — see note)
- Icon stroke color (dark): `#FB923C` (light amber — see note)

> Note: These icon stroke colors (`#C2410C`, `#FB923C`) do not have AppColors token names. They are specified by the reference mockup. Treat as widget-local constants inside InsightCard:
> `static const Color _warningIconLight = Color(0xFFC2410C);`
> `static const Color _warningIconDark = Color(0xFFFB923C);`
> No new AppColors entry required.

### Severity: info
- Icon background (light): blue-100 tint = `AppColors.brandPrimaryGlow` (#303D5A99 = brandPrimary at ~19% opacity) applied as solid: `Color(0xFFD6DCF0)` (lightened brand)
- Icon background (dark): `AppColors.brandSurface` (#1E2E52)
- Icon stroke (light): `AppColors.brandPrimary` (#3D5A99)
- Icon stroke (dark): `AppColors.brandPrimary` (#3D5A99)

> `Color(0xFFD6DCF0)` is not a named token. Use widget-local const:
> `static const Color _infoIconBgLight = Color(0xFFD6DCF0);`

### Severity: success (savings goal / positive)
- Icon background (light): green-100 = `#DCFCE7`
- Icon background (dark): deep green = `#14532D`
- Icon stroke (light): `#15803D`
- Icon stroke (dark): `AppColors.success` (#4CAF50) — nearest token; use for dark stroke

> Light background `#DCFCE7` and stroke `#15803D` are widget-local constants:
> `static const Color _successIconBgLight = Color(0xFFDCFCE7);`
> `static const Color _successIconStrokeLight = Color(0xFF15803D);`
> Dark background `#14532D` is widget-local:
> `static const Color _successIconBgDark = Color(0xFF14532D);`

---

## Section Header ("This week")

The section header sits above the stacked InsightCards and is not part of the InsightCard widget itself.

- Text: "THIS WEEK" (uppercase)
- Typography: `caption2` (11pt/400/ls0.4), uppercase transformation applied to string
- Color: `textSecondaryLight` / `textSecondary`
- Margin: 18dp top, 10dp bottom
- No right-side link (unlike "Recent" section)

---

## Card Tokens

| Element | Light | Dark |
|---------|-------|------|
| Card background | `bgElevatedLight` (#FFFFFF) | `bgSecondary` (#181C27) |
| Card border | `borderLight` (#C8C4BC) | `border` (#2E3453) |
| Card border width | 1dp | 1dp |
| Card radius | `AppRadius.lg` (14dp) | `AppRadius.lg` (14dp) |
| Card padding V | 12dp | 12dp |
| Card padding H | 14dp | 14dp |
| Card bottom margin | `AppSpacing.sm` (8dp) | `AppSpacing.sm` (8dp) |
| Card horizontal margin | `AppSpacing.lg` (16dp) | `AppSpacing.lg` (16dp) |
| Card shadow (light only) | 0 2dp 8dp rgba(0,0,0,0.04) | none |
| Icon container size | 36×36dp | 36×36dp |
| Icon container radius | 10dp explicit | 10dp explicit |
| Icon size | 18×18dp | 18×18dp |
| Icon-to-text gap | `AppSpacing.md` (12dp) | `AppSpacing.md` (12dp) |
| Title typography | `bodyMedium` (16pt/500) | `bodyMedium` (16pt/500) |
| Title color | `textPrimaryLight` | `textPrimary` |
| Subtitle gap | 2dp explicit | 2dp explicit |
| Subtitle typography | `caption1` (12pt/400) | `caption1` (12pt/400) |
| Subtitle color | `textSecondaryLight` | `textSecondary` |

---

## States

### Default (non-tappable)
- Card renders as described above
- No ripple, no ink effect
- No trailing arrow

### Default (tappable — `onTap` provided)
- Full card wrapped in `InkWell` with ripple
- Ink color: `AppColors.brandPrimaryGlow` (#303D5A99)
- `borderRadius` on InkWell matches card: 14dp
- No trailing chevron/arrow icon in V1
- Tap → execute `onTap` callback (typically `context.go(insight.actionRoute)`)

### Loading (shimmer — while insightsProvider is loading)
- Entire "This week" section shows shimmer placeholder:
  - Section header: shimmer bar 60dp×10dp
  - Card 1: card shape with shimmer content:
    - Icon area: shimmer circle/square 36×36dp
    - Title: shimmer bar 160dp×14dp
    - Subtitle: shimmer bar 120dp×10dp
  - Card 2: same as card 1
- Shimmer colors match card background token per theme

### Empty (0 insights generated)
- Entire "This week" section (header + cards) is hidden — `Visibility(visible: false)` or conditional render
- No empty state placeholder shown for this section
- The section occupies no vertical space when hidden

### Error (insightsProvider returns error)
- Section header still visible
- Single card with generic text: "Insights unavailable" — `caption1`, `textSecondaryLight` / `textSecondary`, centered
- No icon

---

## Display Logic (from ADR-011 + epic spec)

- Maximum 2 InsightCards shown on Home tab
- Sort order: warning → info → success (by severity)
- If more than 2 insights generated: show top 2 by severity then recency
- 0 insights: hide section entirely
- The section header "This week" is only rendered when at least 1 card is visible

---

## Interactions

- Tappable card: `InkWell` ripple, `onTap` → `context.go(insight.actionRoute!)`
  - Guard: only call `context.go` if widget is `mounted`
- Non-tappable card: no gesture
- No swipe-to-dismiss in V1
- Long-press: no action in V1

---

## Accessibility

- Tappable card semantic label: "{title}. {subtitle}. Tap for details."
- Non-tappable card semantic label: "{title}. {subtitle}."
- `button: true` only on tappable variant
- Icon container: `excludeSemantics: true` — decorative
- Section header: plain text, read by screen reader in scroll order
- Focus order: section header → card 1 → card 2

---

## Edge Cases

| Case | Behavior |
|------|----------|
| Title > available width | Single line, `overflow: ellipsis` |
| Subtitle > available width | Single line, `overflow: ellipsis` |
| Both title and subtitle empty | Do not render card (provider should never emit this) |
| `onTap` provided but `actionRoute` is null | Card is non-tappable; `onTap` treated as null |
| Insight id `'concentration'` appears twice | Deduplication in provider layer — UI renders whatever list it receives |
