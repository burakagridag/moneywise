# HomeHeader — Component Spec

**Component:** HomeHeader
**Epic:** Epic 8A — Home Tab Redesign
**Related story:** EPIC8A-UX

---

## Purpose

Greet the user by name and time of day. Anchor the Home tab with context (who, when). Secondary function: avatar tap navigates to More/Settings.

---

## Layout

```
┌────────────────────────────────────────────┐  margin: 16dp horizontal, 8dp top, 20dp bottom
│  [date text]                   [  B  ]     │
│  [greeting text]               [ 36dp]     │
└────────────────────────────────────────────┘
```

- Left column: date (top, caption style) + greeting (bottom, headline style)
- Right column: avatar circle, 36×36 dp
- Horizontal alignment: space-between
- Vertical alignment: flex-start (so multiline greeting aligns with avatar top)

---

## Content Rules

### Greeting text
- 05:00–11:59 → "Good morning" / "Good morning, {name}"
- 12:00–17:59 → "Good afternoon" / "Good afternoon, {name}"
- 18:00–04:59 → "Good evening" / "Good evening, {name}"
- If `userName` is null or empty string: omit name entirely, show greeting only

### Date format
- EN locale: `Thursday, 30 April`
- TR locale: `30 Nisan Perşembe`
- Uses `DateFormat` from the `intl` package; resolved from device locale

### Avatar
- 36×36 dp circle
- Content: first character of `userName`, uppercased
- If `userName` null/empty: show a generic person icon (system icon, 18dp, `textSecondary` color)
- Background: `bgSecondaryLight` (light) / `bgSecondary` (dark)
- Border: 1dp, `borderLight` (light) / `border` (dark)
- Text color: `textSecondaryLight` (light) / `textSecondary` (dark)
- Font: 13pt, weight 600
- Tap target: minimum 44×44 dp (add padding around 36dp circle to reach 44dp)
- Tap action: navigate to `/more`

---

## Tokens

| Element | Token (light) | Token (dark) | Value |
|---------|--------------|-------------|-------|
| Date text color | `textSecondaryLight` | `textSecondary` | #5C5E6B / #8A90A8 |
| Date typography | `caption1` | `caption1` | 12pt/400, ls 0.3 |
| Greeting text color | `textPrimaryLight` | `textPrimary` | #1A1C24 / #F0F2F8 |
| Greeting typography | `headline` | `headline` | 17pt/600, ls 0.1 |
| Avatar background | `bgSecondaryLight` | `bgSecondary` | #EEECEA / #181C27 |
| Avatar border | `borderLight` | `border` | #C8C4BC / #2E3453 |
| Avatar text | `textSecondaryLight` | `textSecondary` | #5C5E6B / #8A90A8 |
| Horizontal margin | `AppSpacing.lg` | `AppSpacing.lg` | 16dp |
| Top margin | `AppSpacing.sm` | `AppSpacing.sm` | 8dp |
| Bottom margin | `AppSpacing.xl` | `AppSpacing.xl` | 20dp |

---

## States

### Default (with userName)
- Date line: locale-formatted date string
- Greeting line: time-appropriate greeting + ", {name}"
- Avatar: initial letter of name

### Default (without userName)
- Date line: locale-formatted date string
- Greeting line: greeting only (no comma, no name)
- Avatar: generic person icon

### Loading (skeleton / shimmer)
- Date line replaced with shimmer bar: 80dp wide, 10dp tall, radius 4dp
- Greeting line replaced with shimmer bar: 160dp wide, 16dp tall, radius 4dp
- Avatar replaced with shimmer circle: 36dp diameter
- Shimmer: animated gradient from `bgSecondaryLight`/`bgTertiary` to `bgTertiaryLight`/`bgTertiary`, sweeping left to right, 1200ms loop

### Error
- Not applicable — HomeHeader uses only local/cached data. Greeting degrades to no-name variant if profile fetch fails; never shows error state.

---

## Interactions

- Avatar tap: navigate to `/more` screen
- No other interactive elements
- Entire header area is NOT tappable (only avatar has tap target)

---

## Accessibility

- Avatar semantic label: "Profile. Tap to open settings." (when name present: "Profile, {name}. Tap to open settings.")
- Greeting: read as plain text by screen reader
- Date: read as plain text by screen reader
- Focus order: greeting → date → avatar
- Dynamic Type: `headline` and `caption1` scale with system text size, clamped at 0.85×–1.3× per epic spec
- Minimum tap target on avatar: 44×44 dp enforced via padding or GestureDetector hitTestBehavior

---

## Edge Cases

| Case | Behavior |
|------|----------|
| Very long user name (>20 chars) | Greeting text wraps to second line; avatar remains top-aligned |
| userName = whitespace only | Treat as empty; show greeting-only variant |
| Locale changes mid-session | Date format updates on next rebuild |
| 12:00:00 exactly | Counted as "Good afternoon" (12:00 inclusive) |
