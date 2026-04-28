# SPEC-003b: App Icon — Final Production Spec (Concept 3 — W Chart)

**Related:** SPEC-003-app-icon-concepts.md, SPEC.md Section 2.1
**Owner:** UX Designer
**Date:** 2026-04-28
**Status:** APPROVED — selected by Product Sponsor. Ready for handoff to graphic designer.

---

## 1. Master Artwork Description

### Canvas

- Dimensions: 1024 × 1024 px
- Color space: sRGB
- Background: solid `brandPrimary` (#FF6B5C) — fills the entire 1024 × 1024 canvas edge-to-edge, including all bleed/safe zones. No gradient. No vignette. No shadow on the background.
- Background token: `AppColors.brandPrimary`

### The Five-Bar W-Chart

Five white vertical bars are arranged horizontally across the lower-center of the canvas. Together they form the outline silhouette of a capital "W" and simultaneously read as a bar chart.

#### Bar Geometry (all measurements at 1024 × 1024 px)

| Bar | Position (W letterform) | Height (% of canvas) | Height (px) | Width (px) | Left edge (px from canvas left) |
|-----|------------------------|----------------------|-------------|------------|----------------------------------|
| 1   | Left leg of W          | 70%                  | 717 px      | 133 px     | 133 px                           |
| 2   | Left valley of W       | 35%                  | 358 px      | 133 px     | 348 px                           |
| 3   | Centre peak of W       | 55%                  | 563 px      | 133 px     | 563 px                           |
| 4   | Right valley of W      | 35%                  | 358 px      | 133 px     | 778 px                           |
| 5   | Right leg of W         | 70%                  | 717 px      | 133 px     | 993 px — right edge at 1126 px (see note below) |

**Note on centering:** The total width of the 5-bar group = 5 bars × 133 px + 4 gaps × 82 px = 665 px + 328 px = 993 px. To center this group on a 1024 px canvas, the left edge of bar 1 begins at (1024 − 993) ÷ 2 = ~15 px. However, because the canvas has 12% bottom padding (≈ 123 px) that shifts the visual center of mass upward, the horizontal centering should be optically adjusted: place the 5-bar group centered horizontally on the canvas (left edge of bar 1 at ~15 px, right edge of bar 5 at ~1008 px). See "Optical Centering" note below.

**Revised layout with explicit left edges (canvas-centered):**

| Bar | Left edge (px) | Right edge (px) |
|-----|----------------|-----------------|
| 1   | 16 px          | 149 px          |
| 2   | 231 px         | 364 px          |
| 3   | 446 px         | 579 px          |
| 4   | 661 px         | 794 px          |
| 5   | 876 px         | 1009 px         |

Gap between bars: 82 px each (≈ 8% of 1024 px canvas).

#### Vertical Alignment

- All bars are **bottom-aligned** to a shared baseline.
- The baseline sits at **88% from the top of the canvas** = 1024 × 0.88 = **901 px from top** (equivalently, 123 px from the bottom edge — the 12% bottom padding).
- Each bar grows upward from this baseline by its respective height value.

Bar top edges (distance from top of canvas):

| Bar | Height (px) | Top edge (px from canvas top) |
|-----|-------------|-------------------------------|
| 1   | 717 px      | 901 − 717 = **184 px**        |
| 2   | 358 px      | 901 − 358 = **543 px**        |
| 3   | 563 px      | 901 − 563 = **338 px**        |
| 4   | 358 px      | 901 − 358 = **543 px**        |
| 5   | 717 px      | 901 − 717 = **184 px**        |

#### Bar Corner Radius

- Top corners of each bar: **4 px radius** at 1024 px scale (rounds the top-left and top-right corners only).
- Bottom corners: **0 px radius** (square, anchored to the baseline). This reinforces the bar-chart reading — bars appear to sit on a floor.
- The 4 px radius at master size scales down proportionally: at 48 px the radius would be ~0.19 px (effectively square — no rounding needed at small sizes, see Section 2 notes).

#### Bar Fill

- Color: `textPrimary` / `AppColors.textPrimary` = #FFFFFF (solid white, full opacity, no alpha).
- No stroke. No drop shadow. No inner glow. Pure flat fill.

#### Optical Centering Note

Because the bars are bottom-heavy (rooted to the baseline at 88% of canvas height), the visual centroid of the composition naturally sits in the lower half. This is intentional and correct for a bar chart. The coral background occupying the upper ~18% of canvas above the tallest bars provides breathing room. The composition should feel grounded, not floating. Do not vertically center the bars — keep the 12% bottom padding exactly as specified.

### Proportions Summary

```
┌─────────────────────────────────────────────────────────┐  ← 0 px top
│                                                         │
│  ← 12% headroom above tallest bars (≈184 px) →         │
│                                                         │
│   ██            ██                                      │  ← Bar 1 & 5 top (184 px from top)
│   ██            ██                                      │
│   ██    ██      ██                                      │  ← Bar 3 top (338 px from top)
│   ██    ██      ██                                      │
│   ██    ██  ██  ██  ██                                  │  ← Bar 2 & 4 top (543 px from top)
│   ██    ██  ██  ██  ██                                  │
│   ██    ██  ██  ██  ██                                  │
│   ████████████████████  ← baseline (901 px from top)   │
│                                                         │
│  ← 12% bottom padding (≈123 px) →                      │
└─────────────────────────────────────────────────────────┘  ← 1024 px bottom
```

The silhouette traced by the tops of bars 1–5 (tall, short, medium, short, tall) forms the outline of a capital "W": two outer legs taller than the two valleys, with a centre peak that sits between the valleys. This dual reading — bar chart AND letter W — is the core concept and must be preserved in all production files.

---

## 2. Size Variants and Readability Matrix

### Rendering Notes by Size Range

**Full detail (96 px and above):** All five bars are individually distinct. Both the W letterform and the bar-chart reading are clear. Bar corner radius is visible. No artwork modifications required.

**Simplified (48–72 px):** The 4 px corner radius at master scale maps to less than 1 px at these sizes — bars will have effectively square tops, which is correct. At 72 px and 48 px the bars remain individually legible but are very narrow (~6–9 px wide). To maintain legibility, the designer may optionally increase each bar's proportional width from 13% to **15–16% of canvas** at these sizes, and reduce gaps from 8% to **6% of canvas**, keeping the 5-bar group centered. This is a minor proportional adjustment, not a separate artwork variant.

**Reduced (29–40 px):** At these sizes the W silhouette is the dominant read. Bar-chart detail (individual bar widths, corner radii) is secondary. The five bars must remain individually distinct — five white stripes on coral. No simplification to fewer bars.

**Notification (20 px):** At 20 px, the canvas is only 20 × 20 px. The five bars each become approximately 2–3 px wide with 1–2 px gaps. The result reads as a coral square with 5 thin white vertical stripes of varying heights — this is acceptable as a branded notification badge. The W letterform is not expected to read at this size.

### Full Size Table

| Delivered Size | Platform / Use | W-chart legibility | Notes |
|---------------|----------------|--------------------|-------|
| 1024 × 1024 px | App Store (iOS) / Play Store listing | Full — both W letterform and bar chart clear | Master file |
| 512 × 512 px | Google Play feature graphic (internal copy) | Full | Not the icon itself; used in Play Store listing banner |
| 192 × 192 px | Android launcher xxxhdpi | Full | Android 4+ |
| 144 × 144 px | Android launcher xxhdpi | Full | |
| 96 × 96 px | Android launcher xhdpi | Full | |
| 72 × 72 px | Android launcher hdpi | All 5 bars legible | Bars are ~9 px wide; proportional width increase recommended |
| 48 × 48 px | Android launcher mdpi | All 5 bars legible (narrow) | Bars ~6 px wide; proportional width increase recommended; W shape dominant |
| 40 × 40 px | iOS Spotlight search, iOS Settings | W shape dominant | 5 stripes clear |
| 29 × 29 px | iOS Settings icon | W shape — 5 stripes visible | |
| 20 × 20 px | iOS notification badge | Coral square with white stripes | W letterform not expected to read; branded color is sufficient |

---

## 3. Android Adaptive Icon Specification

### Canvas and Safe Zone

- Total adaptive icon canvas: **108 × 108 dp**
- Safe zone diameter for all launcher mask shapes (circle, rounded square, squircle, teardrop): **72 dp diameter** = inner circle centered on the 108 × 108 dp canvas
- Content safe zone (rectangular area that is guaranteed visible in all masks): **66 × 66 dp** centered on the 108 × 108 dp canvas (i.e., inset 21 dp from each edge)
- All five W-chart bars must be positioned entirely within this **66 × 66 dp safe zone**.

### Foreground Layer

- File name: `ic_launcher_foreground` (vector drawable)
- File path: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Format: Android Vector Drawable (described in plain English below for the designer to produce; the engineer will convert to XML)
- Canvas size declared in the vector: 108 dp × 108 dp
- Artwork: the five white W-chart bars, scaled to fit within the 66 × 66 dp safe zone, horizontally and vertically centered on the 108 dp canvas.
- Background of the foreground layer: **fully transparent** (alpha = 0).
- Bar dimensions within the safe zone (66 dp available width):

| Bar | W-chart height as % of safe zone height | Approx height (dp) | Width (dp) |
|-----|----------------------------------------|---------------------|------------|
| 1   | 70%                                     | 46 dp               | 8.5 dp     |
| 2   | 35%                                     | 23 dp               | 8.5 dp     |
| 3   | 55%                                     | 36 dp               | 8.5 dp     |
| 4   | 35%                                     | 23 dp               | 8.5 dp     |
| 5   | 70%                                     | 46 dp               | 8.5 dp     |

Gap between bars within safe zone: ~5.4 dp.
Total bar group width: 5 × 8.5 dp + 4 × 5.4 dp = 42.5 + 21.6 = ~64 dp (fitting within 66 dp with ~1 dp margin each side).

Bottom padding within safe zone: ~8 dp from the bottom edge of the safe zone to the bar baseline.

- Bar tops: rounded corners 0.25 dp at adaptive canvas scale.
- Bar fill: #FFFFFF, full opacity.
- No shadows, no strokes.

### Background Layer

- File name: `ic_launcher_background` (color resource or vector)
- File path: `android/app/src/main/res/drawable/ic_launcher_background.xml`
- Content: solid color fill `AppColors.brandPrimary` = #FF6B5C
- The entire 108 × 108 dp canvas fills with coral. No artwork on this layer.
- Alternative: define as a color resource in `res/values/colors.xml` as `ic_launcher_background` referencing `#FF6B5C`.

### Maskable Icon

The combination of the foreground layer (bars in safe zone) and background layer (full coral) produces a maskable icon that displays correctly in every Android launcher mask shape, including circle. Because all bar artwork is within the 66 dp safe zone (which sits within the 72 dp safe circle), no bar will be clipped by any mask.

### Mipmap Density Folders

The following `mipmap-*` folders must contain rendered PNG assets of `ic_launcher` (the composite), `ic_launcher_foreground`, and `ic_launcher_round`:

| Folder | Density | Icon size (px) |
|--------|---------|----------------|
| `mipmap-mdpi` | 1× | 48 × 48 |
| `mipmap-hdpi` | 1.5× | 72 × 72 |
| `mipmap-xhdpi` | 2× | 96 × 96 |
| `mipmap-xxhdpi` | 3× | 144 × 144 |
| `mipmap-xxxhdpi` | 4× | 192 × 192 |

The `ic_launcher_foreground.xml` and `ic_launcher_background.xml` vector files live in `drawable/` and are referenced by `mipmap-anydpi-v26/ic_launcher.xml` and `mipmap-anydpi-v26/ic_launcher_round.xml` for API 26+ adaptive icon support.

---

## 4. iOS Icon Requirements

### Technical Rules

- **No transparency.** Every pixel must have full opacity (alpha = 1.0). Transparent pixels cause App Store Connect rejection.
- **No alpha channel.** Export as PNG-24 without alpha, or flatten to a white background before export (though this spec uses a solid coral background so transparency should never arise).
- **No rounded corners in the source file.** iOS applies the squircle mask automatically; exporting pre-rounded art causes double-rounding artifacts.
- **Color space:** sRGB. Do not use Display P3 or AdobeRGB.
- **File format:** PNG.

### Required Sizes

| Size (px) | Usage |
|-----------|-------|
| 1024 × 1024 | App Store Connect submission (mandatory) |
| 180 × 180 | iPhone home screen (@3×, 60 pt) |
| 167 × 167 | iPad Pro home screen (@2×, 83.5 pt) |
| 152 × 152 | iPad home screen (@2×, 76 pt) |
| 120 × 120 | iPhone home screen (@2×, 60 pt) and Spotlight (@3×, 40 pt) |
| 87 × 87 | iPhone Settings (@3×, 29 pt) |
| 80 × 80 | Spotlight (@2×, 40 pt) |
| 76 × 76 | iPad home screen (@1×, 76 pt) |
| 60 × 60 | iPhone home screen (@1×) |
| 58 × 58 | iPhone Settings (@2×, 29 pt) |
| 55 × 55 | Apple Watch notification |
| 40 × 40 | Spotlight (@1×, 40 pt) and iPad Spotlight (@2×, 20 pt) |
| 29 × 29 | Settings (@1×, 29 pt) |
| 20 × 20 | iPad Spotlight (@1×) and notification |

All files must be square. Do not pad with whitespace.

### Naming Convention (iOS)

Use the following naming pattern for the iOS asset catalog (`AppIcon.appiconset`):
`AppIcon-{size}@{scale}x.png`

Examples:
- `AppIcon-1024@1x.png`
- `AppIcon-60@3x.png` (180 px)
- `AppIcon-60@2x.png` (120 px)
- `AppIcon-29@3x.png` (87 px)

The `Contents.json` file in the asset catalog will be generated by flutter_launcher_icons or by Xcode — the designer does not need to produce this file.

---

## 5. Dark/Light Mode Variant Policy

There is **one icon variant only.** The coral background (`brandPrimary` #FF6B5C) is the single, universal icon for all contexts:

- iOS light mode home screen: coral is vibrant and stands out against white/grey backgrounds.
- iOS dark mode home screen: coral stands out against dark wallpapers equally well.
- Android light launcher: same as iOS light.
- Android dark launcher: same as iOS dark.

**No dark-mode alternate icon is required.**

iOS 18 introduced "dark" and "tinted" icon variants (where iOS can apply a tint or desaturate the icon to match the user's dark home screen). For V1, MoneyWise will not supply these alternate variants. The standard (coral) icon will be used in all modes. This decision can be revisited in V2 if user feedback indicates a preference.

**Why coral works universally:** Unlike a dark-background icon that risks visual blending on dark home screens, a coral icon creates contrast against both light and dark backgrounds. The single-icon strategy also reduces designer deliverable scope and eliminates maintenance of multiple asset variants.

---

## 6. Deliverables Checklist for Graphic Designer

The graphic designer must deliver every file listed below. All PNG files must be sRGB, no alpha channel, no transparency. Vector files should be delivered as both the source format (Figma, Illustrator, or SVG) and exported as specified.

### Master Source Files

1. `AppIcon-master-1024.png` — 1024 × 1024 px, PNG-24, no alpha, no rounded corners. This is the App Store submission file and the source for all other sizes.
2. `AppIcon-master.svg` or `AppIcon-master.ai` — the vector source file in the designer's native tool (Figma component, Illustrator artboard, or SVG). Must be fully editable with labeled layers: "background" (coral rectangle) and "bars" (5 white rectangles).

### iOS PNG Set (17 files)

3. `AppIcon-1024@1x.png` — 1024 × 1024 px
4. `AppIcon-180@1x.png` — 180 × 180 px (60 pt @3×)
5. `AppIcon-167@1x.png` — 167 × 167 px (83.5 pt @2×)
6. `AppIcon-152@1x.png` — 152 × 152 px (76 pt @2×)
7. `AppIcon-120@1x.png` — 120 × 120 px (60 pt @2× / 40 pt @3×)
8. `AppIcon-87@1x.png` — 87 × 87 px (29 pt @3×)
9. `AppIcon-80@1x.png` — 80 × 80 px (40 pt @2×)
10. `AppIcon-76@1x.png` — 76 × 76 px (76 pt @1×)
11. `AppIcon-60@1x.png` — 60 × 60 px
12. `AppIcon-58@1x.png` — 58 × 58 px (29 pt @2×)
13. `AppIcon-55@1x.png` — 55 × 55 px (Apple Watch)
14. `AppIcon-40@1x.png` — 40 × 40 px
15. `AppIcon-29@1x.png` — 29 × 29 px
16. `AppIcon-20@1x.png` — 20 × 20 px
17. `AppIcon-512@1x.png` — 512 × 512 px (Google Play feature graphic use, also a useful intermediate for Android generation)

### Android PNG Set — ic_launcher (5 files)

18. `ic_launcher-mdpi.png` — 48 × 48 px
19. `ic_launcher-hdpi.png` — 72 × 72 px
20. `ic_launcher-xhdpi.png` — 96 × 96 px
21. `ic_launcher-xxhdpi.png` — 144 × 144 px
22. `ic_launcher-xxxhdpi.png` — 192 × 192 px

### Android PNG Set — ic_launcher_round (5 files, identical content to ic_launcher)

23. `ic_launcher_round-mdpi.png` — 48 × 48 px
24. `ic_launcher_round-hdpi.png` — 72 × 72 px
25. `ic_launcher_round-xhdpi.png` — 96 × 96 px
26. `ic_launcher_round-xxhdpi.png` — 144 × 144 px
27. `ic_launcher_round-xxxhdpi.png` — 192 × 192 px

### Android Adaptive Icon Foreground (1 file)

28. `ic_launcher_foreground.svg` — 108 × 108 dp vector canvas, transparent background, white bars centered within the 66 × 66 dp safe zone. The flutter engineer will convert this to an Android Vector Drawable XML. The designer must also export it as a PNG at 432 × 432 px (4× the dp canvas at xxxhdpi) for reference: `ic_launcher_foreground-xxxhdpi.png`.

### Notification Icon (1 file)

29. `ic_notification.svg` — 24 × 24 dp vector, white fill, transparent background. Simplified W-chart mark: five white vertical bars (as simple rectangles, no corner radius needed) on transparent background. This is used as the Android status bar notification icon and must meet Android's requirement for a single-color (white), alpha-masked icon. Also export as `ic_notification-mdpi.png` (24 × 24 px) and `ic_notification-xxhdpi.png` (72 × 72 px).

### Total Files: 31 deliverables

---

## 7. Vector Description for AI and Designer Tools

The following description is written for a graphic designer or AI image generation tool (Figma auto-layout, Adobe Illustrator, or a prompt-based tool). Use this text verbatim or as a creative brief.

---

**Design brief — MoneyWise App Icon**

Create a flat, two-color app icon on a 1024 × 1024 pixel square canvas.

**Background:** Fill the entire canvas with solid coral red, hex color #FF6B5C. No gradient, no vignette, no texture, no rounded corners on the canvas itself (the OS applies rounding). The coral fills 100% of all 1024 × 1024 pixels.

**Foreground:** Draw five solid white rectangles (bars) arranged horizontally across the lower portion of the canvas. The bars have no stroke, no shadow, no opacity change — pure flat white (#FFFFFF). The five bars represent both a bar chart and the letter "W" simultaneously. This dual reading is the central design idea.

**Bar dimensions and positions (all measurements in pixels on the 1024 px canvas):**

- Bar 1 — leftmost: 133 px wide, 717 px tall (70% of canvas height). Left edge at x = 16 px. Bottom edge at y = 901 px (the baseline). Top edge at y = 184 px. Top corners rounded at 4 px radius; bottom corners square.
- Bar 2: 133 px wide, 358 px tall (35% of canvas height). Left edge at x = 231 px. Bottom at y = 901 px. Top at y = 543 px. Same corner treatment.
- Bar 3 — center: 133 px wide, 563 px tall (55% of canvas height). Left edge at x = 446 px. Bottom at y = 901 px. Top at y = 338 px. Same corner treatment.
- Bar 4: 133 px wide, 358 px tall (35% of canvas height). Left edge at x = 661 px. Bottom at y = 901 px. Top at y = 543 px. Same corner treatment.
- Bar 5 — rightmost: 133 px wide, 717 px tall (70% of canvas height). Left edge at x = 876 px. Bottom at y = 901 px. Top at y = 184 px. Same corner treatment.

The gap between each pair of adjacent bars is 82 px.

**Visual check:** Tracing the five bar tops from left to right traces the outline of a capital "W": tall (bar 1), drop to a valley (bar 2), rise to a peak (bar 3), drop to a valley (bar 4), rise back to tall (bar 5). The composition simultaneously reads as a bar chart showing growth and as the letterform "W".

**Spacing:** 12% of canvas height (approximately 123 px) of empty coral sits below the baseline. Approximately 18% of canvas height (approximately 184 px) of empty coral sits above the tallest bars. The bars are horizontally centered. The bottom padding ensures the composition feels grounded and not floating.

**Do not add:** gradients, shadows, glows, outlines, background shapes, text, letterforms, borders, or any element other than the coral background rectangle and the five white bar rectangles.

**Color summary:** Two colors only. Background: #FF6B5C. Bars: #FFFFFF.

**Layer naming (for Figma or Illustrator):**
- Layer 1 (bottom): "background" — 1024 × 1024 coral rectangle
- Layer 2 (top): "bars" — group containing five white rectangles named "bar-1" through "bar-5"

---

## Open Questions (Resolved)

- **Q: Dark-mode variant?** Resolved: No separate dark-mode icon. Single coral icon used universally. (See Section 5.)
- **Q: Notification icon — W silhouette or simplified bars?** Resolved: Five-bar simplified silhouette (five equal-width white bars at varying heights) used as notification icon. The letterform is not expected to read at 20–24 dp.
- **Q: Bar corner radius at small sizes?** Resolved: At 72 dp and below, corner radius rounds to less than 1 px and becomes effectively square. Designer should not apply sub-pixel radii at small sizes — square bar tops are correct for those sizes.
- **Q: Should proportional bar widths be increased at small sizes?** Resolved: Yes. At 48 dp and 72 dp, each bar width may be increased from 13% to 15% of canvas and gaps reduced from 8% to 6% to maintain bar legibility. This is a minor proportional adjustment within the same artwork concept, not a new variant.
