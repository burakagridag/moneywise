# EPIC8C-01: Budget Screen Redesign — Mini-Spec

**Status:** Sponsor approved — ready for Sprint 8c implementation
**Sprint:** 8c
**Estimate:** 5pt (M)
**Owner agent:** UX Designer → Flutter Engineer
**Reference files:**
- `v1-reference-light.html`
- `v1-reference-dark.html`
- (Sponsor mockup history: chat session 2026-05-07)

---

## Overview

Bütçe sekmesi şu anda kategori bazlı bir liste artı küçük bir özet kartından ibaret: Home tab'ın görsel kalitesinin gerisinde, insight engine'den hiç beslenmiyor, ve global budget kavramı kullanıcıya görünmüyor. EPIC8C-01 Bütçe ekranını Home tab'ın tasarım dilinde yeniden inşa eder: slate-blue hero card, glanceable metric cards, insight integration, kategori listesinin sade hali ve dağılım donut'u. Bu epic **redesign'ın iskeleti**dir; üzerine EPIC8B-07 (global budget direct input) ve EPIC8B-06 (kategori breakdown chart) sıralı olarak biner.

---

## Sıra ve Dependency

| Sıra | Story | Bu Epic'le İlişkisi |
|------|-------|---------------------|
| 1 | **EPIC8C-01 (bu)** | Redesign zeminini kurar (hero kart, layout, insight slot, donut placeholder, kategori listesi UX) |
| 2 | EPIC8B-07 Global Budget Settings | EPIC8C-01'in hero kartını editable hale getirir, fallback chain'i implement eder |
| 3 | EPIC8B-06 Category Breakdown Chart | EPIC8C-01'deki donut placeholder'ı production-grade chart ile doldurur |

EPIC8C-01 kendi başına **shippable**: hero kart static (kategori-toplam fallback ile), donut placeholder (mockup'taki gibi 2-segment SVG), insight bölümü Home'daki rule engine'e bağlı. EPIC8B-07 ve 8B-06 bu zemini olgunlaştırır, parçalamaz.

---

## Kapsam (In Scope)

### 1. Hero Card (Slate-blue gradient)
- Mevcut "Kalan (Aylık)" gri kartı tamamen değiştirir
- Slate-blue gradient (Home Total Balance kartı paritesi) — `#3D5A99 → #4A6BAE`
- Büyük tipografi: kalan tutar (32px / 500 weight, tabular-nums)
- Pace bar: progress + "ideal nokta" işaretçisi
- "X gün kaldı" sağ üstte
- "Y € harcandı / İdeal hız: Z €" altta küçük satır
- **Tap target:** kart tappable (EPIC8B-07 hero kartı edit modal'ı açacak; bu epic'te tap → toast "Yakında" veya placeholder)

### 2. Metrik Kartları (2x grid)
- "GÜNLÜK" — daily pace + spendable amount, success-green vurgu
- "GEÇEN AY" — geçen ay total + delta (% azalış / artış)
- 2 sütun grid, gap 10px, beyaz bg, hafif border

### 3. Insight Slot (Optional)
- Home insight engine'inden Bütçe-relevant insight'ları çeker
- **Klasifikasyon:** Concentration, BigTransaction (kategori-bazlı sinyaller)
- **Home insight'ları (WeekendSpending, Overspending pace) burada görünmez** — duplicate önlenir
- Boş ise bölüm tamamen gizli (clean state)
- Maksimum 1 insight gösterilir (overflow bottom sheet'e açılır — V1.x)

### 4. Kategoriler Listesi
- Sadece bütçesi olan kategoriler görünür
- Empty kategoriler (`budget == 0` veya `budget == null`) collapse'lı satıra:
  - "X kategori daha — bütçesi yok"
  - Tap → full liste açılır (bu epic'te) veya kategori seçim modalı (EPIC8B-07'nin parçası)
- Her kategori satırı:
  - Emoji icon (32x32, secondary bg)
  - Kategori adı (14px, 500 weight)
  - "harcanan / bütçe" (12px, secondary color)
  - Mini progress bar (4px height, slate-blue fill)
- Tap satır → mevcut kategori edit dialog (Image 3 reference) açılır — değişmez
- Üst sağda "Düzenle ›" linki → mevcut "Bütçe Ayarı" sayfasına gider

### 5. Dağılım (Donut Placeholder)
- 2-segment SVG donut (mockup'taki gibi)
- Yanında legend (kategori adı + yüzde)
- "Bu ay X € harcandı" alt satır
- **Bu epic'te placeholder'dır** — EPIC8B-06 prod-grade chart ile değiştirir
- Header'da `Bu ay <total> €` küçük bilgi

### 6. Header & Navigation
- Sol: "Bütçe" başlığı (22px, 500 weight) — Home'daki "Good evening" pattern'i
- Sağ: search icon (gri) + filter icon (slate-blue, "Bütçe Ayarı" sayfasına gider)
- Alt: ay seçici "‹ Mayıs 2026 ›" (mevcut pattern korunur)

### 7. Empty State (Yeni Kullanıcı)
- Hero kart: "Aylık bütçeni belirle" başlığı + açıklayıcı 2 satır
- Tek CTA: "Bütçeyi başlat" (primary button)
- Diğer bölümler hidden: metrik kartları, insight, kategoriler, donut yok
- "Bütçeyi başlat" → kategori bütçeleri ekleme flow'u (mevcut ekrana yönlendirme)
- Footer: "Sonra ayarla" link (skip)

### 8. Kategori Seçim Modal (Yeni — Empty State'ten Çağrılır)
- Bottom sheet
- Tüm sistem kategorileri grid (icon + ad)
- Seçilen kategoriler highlight
- "Devam et" CTA → seçili kategoriler için bütçe input ekranı (mevcut "Bütçe Ayarı" reuse)
- Bu mockup paketinde reference HTML'de gösterilir; implementation EPIC8C-01 scope'undadır

---

## Out of Scope

- ❌ Edit modal'ın global budget direct input fonksiyonu — **EPIC8B-07**
- ❌ Donut chart prod-grade implementation (animation, tap-to-detail, drill-down) — **EPIC8B-06**
- ❌ Multi-month trend grafiği (geçmiş aylar timeline)
- ❌ Insight overflow bottom sheet (1+ insight stacking)
- ❌ Kategori detay sayfası — zaten Settings altında mevcut, değişmez
- ❌ Kategori CRUD (ekle/sil/yeniden adlandır) — Settings'te mevcut, değişmez
- ❌ Currency switcher — Sprint 8d Account Onboarding kapsamı

---

## Dark Mode + Design Token'ları

Home redesign'da kullanılan tokens'ı **birebir reuse** eder. Tek source of truth, iki ekran arasında tutarlılık:

### Light Mode
- Background: `#F7F6F3` (warm beige)
- Surface: `#FFFFFF`
- Border: `#C8C4BC`
- Brand: `#3D5A99`
- Text primary: `#1A1C24`
- Text secondary: `#5C5E6B`
- Success: `#047857`
- Danger: `#C0392B`

### Dark Mode
- Background: `#0F1117`
- Surface: `#181C27`
- Border: `#2E3453`
- Brand (dark variant): `#6366F1`
- Text primary: `#F0F2F8`
- Text secondary: `#8A90A8`
- Success: `#34D399`
- Danger: `#E55A4E`

### Hero Gradient (Both Modes)
- Light: `#3D5A99 → #2E4A87`
- Dark: `#4F46E5 → #3D5A99`

---

## i18n Gereksinimleri (Yeni ARB Key'ler)

EN + TR, sponsor approval **PR öncesi** zorunlu (Sprint 8b retro Madde 5).

| Key | EN | TR |
|-----|-----|-----|
| `budgetScreenTitle` | Budget | Bütçe |
| `budgetHeroLabelRemaining` | REMAINING THIS MONTH | KALAN BU AY |
| `budgetHeroDaysLeft` | {n} days left | {n} gün kaldı |
| `budgetHeroSpentOf` | {spent} of {budget} | {budget} bütçeden |
| `budgetHeroIdealPace` | Ideal pace: {amount} | İdeal hız: {amount} |
| `budgetMetricDailyTitle` | DAILY | GÜNLÜK |
| `budgetMetricDailySafe` | {amount} can spend | {amount} harcayabilirsin |
| `budgetMetricLastMonthTitle` | LAST MONTH | GEÇEN AY |
| `budgetMetricDelta` | ↓ {pct}% less | ↓ %{pct} daha az |
| `budgetCategoriesTitle` | CATEGORIES | KATEGORİLER |
| `budgetCategoriesEditLink` | Edit › | Düzenle › |
| `budgetCategoriesCollapsedCount` | {n} more categories | {n} kategori daha |
| `budgetCategoriesCollapsedSubtitle` | No budget set | Bütçesi yok |
| `budgetDistributionTitle` | DISTRIBUTION | DAĞILIM |
| `budgetDistributionFooter` | This month {amount} | Bu ay {amount} |
| `budgetEmptyTitle` | Set your monthly budget | Aylık bütçeni belirle |
| `budgetEmptySubtitle` | Track spending across categories | Kategorilere göre harcamalarını takip et |
| `budgetEmptyCTA` | Start budget | Bütçeyi başlat |
| `budgetEmptySkip` | Set later | Sonra ayarla |
| `budgetCategoryPickerTitle` | Select categories | Kategorileri seç |
| `budgetCategoryPickerCTA` | Continue ({n}) | Devam et ({n}) |

**Insight body string'leri:** Mevcut insight ARB key'leri reuse edilir (yeni key gerekmez).

---

## Test Coverage

### Widget Tests
- Hero card render: kalan, pace bar, days-left
- Metric card render: günlük, geçen ay, delta hesaplaması
- Insight slot: hidden when empty, render when present, max 1 görünür
- Category list: sıralama (descending by spent), empty collapse
- Empty state: hero CTA tıklandığında kategori seçim modal'ı açılır
- Dark mode parity: tüm bölümler dark mode'da render olur

### Integration Tests
- Bütçe varken redesign render edilir
- Bütçe yokken empty state render edilir
- Kategori-toplam fallback hero kartında doğru tutar
- Insight engine kategori-bazlı insight verince Bütçe ekranında görünür
- Insight engine WeekendSpending verince Bütçe ekranında **görünmez** (klasifikasyon)

### Smoke Test (Sponsor Pre-PR Gate)
- F1: Verili bütçe + 2 kategori + 1 insight (light + dark, EN + TR — 4 screenshot)
- F2: Empty state (light + dark, EN + TR — 4 screenshot)
- F3: 13 kategori, 2 budget'lı + 11 collapse — collapse satırı doğru sayım
- F4: Kategori seçim modal'ı açılır, seçim yapılır, devam et çalışır

---

## ADR Etkisi

- **ADR-013 Insight Rule Engine** güncellenir: Insight klasifikasyonu eklenir
  - "Home-only insights": WeekendSpending, OverspendingPace
  - "Budget-only insights": Concentration, BigTransaction (V1.x: per-category)
  - Implementation: `Insight.surface` enum field veya rule-level `surfaces: Set<InsightSurface>` property
- **Yeni ADR önerisi: ADR-015 Design Token Unification** (Home + Bütçe ortak token sistemi)
  - Light/dark token'lar tek dosyada
  - Future screens (Transactions, More) bu token sistemini kullanır

---

## Effort Breakdown (5pt)

| Görev | Pt |
|-------|-----|
| Hero card widget (gradient, pace bar, marker) | 0.75 |
| Metric cards (2x grid, delta calc) | 0.5 |
| Insight slot integration + klasifikasyon | 0.75 |
| Category list refactor (sıralama, collapse) | 0.75 |
| Donut placeholder SVG | 0.25 |
| Empty state widget + CTA flow | 0.5 |
| Kategori seçim modal (bottom sheet) | 0.75 |
| ARB keys (EN + TR, ~22 string) | 0.25 |
| Widget tests | 0.5 |
| Smoke test + sponsor review iteration | 0.5 (buffer) |
| **Toplam** | **5pt** |

**Risk:** Insight klasifikasyonu (ADR-013 update) cross-cutting concern. Mevcut 5 rule'un her birinde `surfaces` property'si eklenmeli. Eğer schema değişikliği büyürse +0.5pt.

---

## Sponsor-Onaylı Kararlar (2026-05-07)

| Karar | Seçenek | Sonuç |
|-------|---------|-------|
| Hero kart yaklaşımı | Slate-blue gradient + büyük tipografi (Home parity) | ✅ Onaylandı |
| Insight kartının yeri | Hero'nun altı, kategorilerden önce | ✅ Onaylandı |
| Empty kategoriler | Collapse pattern ("X kategori daha") | ✅ Onaylandı |
| Donut konumu | En altta (analitik bölüm) | ✅ Onaylandı |
| Insight klasifikasyonu | Home-only / Budget-only (duplicate önlenir) | ✅ Onaylandı |
| Hero kartı tappable | EPIC8B-07'de edit modal açacak | ✅ Onaylandı |
| Empty state CTA | "Bütçeyi başlat" → kategori seçim modal | ✅ Onaylandı |
| Design token reuse | Home redesign tokens'ı 1:1 reuse | ✅ Onaylandı |
| Bu epic ilk, 8B-07 ve 8B-06 sonra | Sponsor explicit sıralama | ✅ Onaylandı |

**Approved by:** burakagridag@gmail.com
**Date:** 2026-05-07
**Reference session:** Sprint 8c Day 1 sponsor review

---

## Open Items (Sponsor Review During Implementation)

- TR wording final review smoke test sırasında — ARB key'ler implement edildikten sonra screenshot ile sponsor onayı (madde 5)
- Empty state mikroyazım: "Aylık bütçeni belirle" yeterli mi, yoksa motivasyonel ek satır mı? Smoke test'te değerlendirilecek
- Hero kartı tappable iken bu epic'te tap davranışı: toast mı placeholder mı no-op mu? — sponsor karar verecek
- Insight max count: 1 mi 2 mi? — implementation sırasında "Bu hafta" bölümünün ekran ağırlığına bakılarak karar
