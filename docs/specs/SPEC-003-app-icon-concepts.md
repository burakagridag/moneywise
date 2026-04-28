# SPEC-003: App Icon Concepts

**Related:** SPEC.md Section 2.4 (Brand logo — "cüzdan + kalem kombinasyonu önerilir")
**Owner:** UX Designer
**Date:** 2026-04-28
**Status:** Proposed — awaiting Product Sponsor selection

---

## Purpose

Define 3 distinct app icon concepts for MoneyWise. One concept will be selected by the Product Sponsor and handed to a graphic designer (or AI image tool) for production-quality rendering at all required sizes.

## Icon Requirements (applies to all concepts)

- Sizes: 1024×1024 (App Store / Play Store), 512×512, 256×256, 120×120, 87×87, 60×60, 40×40, 29×29, 20×20 (notification badge)
- Shape: Square canvas with rounded corners applied by the OS (iOS: squircle mask, Android: adaptive icon with foreground + background layers)
- No text or wordmarks — Apple App Store and Google Play policy prohibition
- No overly complex gradients — flat fills or a single, subtle drop shadow only
- Foreground symbol must remain legible at 20×20 (notification size): reduce to its simplest silhouette
- Android adaptive icon: foreground artwork must be centered within the safe zone (inner 66% of the 108dp canvas) so no element is clipped by any launcher mask shape

---

## Concept 1 — "Wallet & Pen"

### Visual Description

Background: solid `bgPrimary` (#1A1B1E) — very dark near-black.

Center of the canvas: a compact, forward-facing wallet rendered in flat style. The wallet body is a rounded rectangle (corners ≈ 12% of its own width). Fill: `brandPrimary` (#FF6B5C). The wallet has a slim fold line across its upper third — a single horizontal stroke in a slightly darker shade of coral (`brandPrimaryDim` #E85A4D), 3–4% of the icon height, purely as a structural detail, not a gradient.

Overlapping the bottom-right corner of the wallet, a simple writing pen (or stylus) is angled at 45 degrees, pointing upper-left. The pen body is white (`textPrimary` #FFFFFF). The pen nib (tip) is `brandPrimary` to unify the two elements. The pen overlaps the wallet corner by roughly 20% of the pen's length — enough to read as "a pen resting on the wallet", not two separate objects.

No additional ornaments. The composition sits slightly above the canvas vertical center to feel optically centered.

```
┌─────────────────────────────────┐
│  bgPrimary (#1A1B1E)            │
│                                 │
│      ┌────────────────┐         │
│      │  brandPrimary  │   /     │
│      │   (wallet)     │  / pen  │
│      │ ─────────────  │ /       │
│      └──────────────┘/          │
│                    ↗            │
│             pen nib             │
│                                 │
└─────────────────────────────────┘
```

### Color Palette

| Element            | Token                  | Hex       |
|--------------------|------------------------|-----------|
| Background         | `bgPrimary`            | #1A1B1E   |
| Wallet body        | `brandPrimary`         | #FF6B5C   |
| Wallet fold line   | `brandPrimaryDim`      | #E85A4D   |
| Pen body           | `textPrimary`          | #FFFFFF   |
| Pen nib            | `brandPrimary`         | #FF6B5C   |

### Rationale

This is the direction explicitly recommended in SPEC.md Section 2.4. The wallet signals personal finance directly; the pen signals active recording / precision. The two-object composition gives the icon a clear story. The dark background matches the app's default dark theme, creating brand continuity on the user's home screen. Coral on near-black exceeds 3:1 contrast for large graphic elements (AA for non-text graphics per WCAG 1.4.11).

### Risk / Concern

Two overlapping objects are harder to read at very small sizes (20×20, 29×29). The pen may dissolve into a diagonal smear at notification size. Mitigation: at sizes below 40×40 the pen should be dropped and only the wallet silhouette rendered — a simplified alternate asset ("notification icon") is required as a separate deliverable. The graphic designer must produce both a full-detail version and a simplified monochrome/small-size version.

---

## Concept 2 — "Upward Coin"

### Visual Description

Background: solid `bgPrimary` (#1A1B1E).

A single large circle representing a coin occupies approximately 70% of the canvas width and is centered on the canvas. The coin circle has a flat fill of `brandPrimary` (#FF6B5C). Inside the coin, centered, is a bold upward-pointing chevron arrow (a "greater-than" rotated 90 degrees, not a full arrowhead with a long shaft). The chevron is drawn with two thick strokes meeting at a point — white (`textPrimary` #FFFFFF), stroke weight approximately 8–9% of the canvas width, with rounded stroke caps for a modern feel.

A thin concentric ring inset 6–7% from the coin edge adds the classic "coin rim" detail — this ring is `brandPrimaryDim` (#E85A4D), 2–3% of canvas width stroke, no fill. This detail disappears gracefully at small sizes (treat as optional below 60×60).

The coin casts a very subtle soft drop shadow directly below it (offset: 0, +4% canvas height; blur radius: 6% of canvas; color: #000000 at 30% opacity). This is the only shadow in the icon — flat otherwise.

```
┌─────────────────────────────────┐
│  bgPrimary (#1A1B1E)            │
│                                 │
│       ╭───────────────╮         │
│      │  brandPrimary   │        │
│      │       /\        │        │
│      │      /  \  ←chevron      │
│      │     /    \      │        │
│       ╰───────────────╯         │
│         [soft shadow]           │
│                                 │
└─────────────────────────────────┘
```

### Color Palette

| Element            | Token                  | Hex              |
|--------------------|------------------------|------------------|
| Background         | `bgPrimary`            | #1A1B1E          |
| Coin body          | `brandPrimary`         | #FF6B5C          |
| Coin rim ring      | `brandPrimaryDim`      | #E85A4D          |
| Chevron arrow      | `textPrimary`          | #FFFFFF           |
| Drop shadow        | (system black, 30% α)  | #00000050        |

### Rationale

A single bold shape with a single bold symbol inside reads instantly at every size — the silhouette of a circle is the most recognizable form at 20×20. The upward chevron communicates growth, progress, and financial control — aspirational for the 22–45 target audience. No secondary object means no readability problem at small sizes. The coin archetype is universally understood as "money" across cultures, making it appropriate for the Turkey-first then global rollout. This concept is the lowest-execution-risk of the three.

### Risk / Concern

A coin with an upward arrow is one of the most common finance app icon patterns in both the App Store and Play Store (budget apps, banking apps, investment apps). The design risks blending into a crowded category. Differentiation relies entirely on the specific coral-on-dark color palette — which is distinctive — but the silhouette alone could be mistaken for a competitor. The Product Sponsor should search "budget tracker" on the App Store before finalizing this concept.

---

## Concept 3 — "W Chart"

### Visual Description

Background: `brandPrimary` (#FF6B5C) — a solid coral fill. This inverts the color relationship from Concepts 1 and 2 and creates an immediately distinctive, warm home-screen presence.

Centered on the canvas: a stylized letterform "W" constructed entirely from 5 vertical bars of varying heights, arranged left to right. The bars represent a bar chart. Their heights, left to right, follow the outline of a capital "W": tall → medium → short (valley) → medium → tall. This creates a shape that simultaneously reads as a bar chart and as the letter W for "Wise" / "MoneyWise". The bars are white (`textPrimary` #FFFFFF), flat fill, with square or very slightly rounded tops (2dp radius at 1024px scale). Bar width is approximately 11% of canvas width; gap between bars is approximately 5% of canvas width.

The five bars sit on a shared invisible baseline at approximately 30% from the bottom of the canvas, so the composition feels grounded. The tallest bars reach to approximately 75% from the bottom, giving roughly 45% of canvas height for the full bar chart.

No outlines. No shadows. Pure flat.

```
┌─────────────────────────────────┐
│  brandPrimary (#FF6B5C)         │
│                                 │
│  ██       ██   ← tall bars      │
│  ██  ██  ████  ← mid bars       │
│  ████████████  ← short valley   │
│  ──────────── baseline          │
│                                 │
└─────────────────────────────────┘
```

Bars from left to right, heights as % of canvas:
1. 45% (tall — left leg of W)
2. 30% (medium — left slope of W)
3. 18% (short — W valley)
4. 30% (medium — right slope of W)
5. 45% (tall — right leg of W)

### Color Palette

| Element            | Token                  | Hex       |
|--------------------|------------------------|-----------|
| Background         | `brandPrimary`         | #FF6B5C   |
| Bar chart bars     | `textPrimary`          | #FFFFFF   |

### Rationale

This concept is the most visually bold and differentiated. The coral background makes it unmistakable on a home screen full of dark or blue finance apps. The W-as-chart concept encodes two ideas at once — analytics / statistics (the core value proposition of a budget tracker) and the brand initial — without any text. At 1024×1024 the dual reading is clear. The extremely limited color palette (two flat colors) makes production simple and guarantees reproduction at every size. It also works well in dark mode and light mode contexts on the home screen since the icon itself provides its own vibrant background.

### Risk / Concern

The W letterform as a bar chart requires careful proportion work: if bar heights are not tuned precisely, the W silhouette becomes ambiguous or reads as random bars rather than a recognizable letter. At 20×20 the five bars will collapse — the icon will read as a coral square with white stripes, not a W. This is acceptable for notification use (a solid brand-colored badge reads well) but the designer must verify this at 20×20 before sign-off. Additionally, a coral background icon will visually clash with iOS's red notification badge dot — a minor but real consideration.

---

## Size Readability Summary

| Concept           | 1024×1024 | 120×120 | 60×60 | 29×29 | 20×20 |
|-------------------|-----------|---------|-------|-------|-------|
| 1 — Wallet & Pen  | Full detail | Full detail | Wallet + pen | Wallet only (pen dropped) | Wallet silhouette |
| 2 — Upward Coin   | Full detail | Full detail | Coin + chevron | Coin + chevron | Circle + chevron (coin rim dropped) |
| 3 — W Chart       | Full detail | Full detail | 5 bars visible | 5 bars visible (narrow) | Coral square + white stripes |

---

## Recommendation

**Concept 2 (Upward Coin)** is the safest execution-risk choice and the most legible at all sizes. It should be the default recommendation if the Product Sponsor has no strong preference.

**Concept 3 (W Chart)** is the most differentiated and best matches the app's analytics identity. Recommended if the Product Sponsor wants a distinctive, bold presence.

**Concept 1 (Wallet & Pen)** is the most literal and directly reflects the SPEC.md brand direction. Recommended if brand consistency with the in-app illustrations (wallet + pen) is a priority.

---

## Deliverables Required from Graphic Designer

Whichever concept is chosen, the following assets must be produced:

1. **1024×1024 PNG** — full detail, on transparent background (for App Store / Play Store)
2. **Adaptive icon foreground** — SVG or 1024×1024 PNG with artwork centered in the safe zone (66% of 108dp canvas), transparent background — for Android
3. **Adaptive icon background** — solid color fill layer (`bgPrimary` or `brandPrimary` depending on concept) — for Android
4. **Simplified notification icon** — 24×24dp vector (SVG), monochrome white, on transparent background — used as Android notification icon and small badge
5. **Dark and light variants** — if the chosen concept uses `bgPrimary` as background (dark), a light variant with `bgPrimaryLight` (#FFFFFF) background should be produced as an optional alternative for iOS light-mode home screens

## Open Questions

- Q1: Does the Product Sponsor want a light-mode icon variant, or is the dark-background icon used universally regardless of device theme? (Apple does not mandate adaptive icons, but supports them via "dark" and "tinted" icon variants in iOS 18.)
- Q2: Is there an in-app illustration asset (onboarding, empty states) planned that should share visual language with the icon? If yes, the chosen icon concept should be handed to the illustrator first.
