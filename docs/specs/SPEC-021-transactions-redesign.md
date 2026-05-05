# EPIC8D-01 — Transactions Screen Redesign

**Sprint:** 8d (preliminary)
**Story Points:** 5pt (preliminary, post-mockup review)
**Status:** Mockup Phase — Sponsor Review Pending
**Author:** Sponsor (Burak)
**Date:** 2026-05-08

---

## 1. Vision

Transactions ekranını mevcut 5-tab yoğun yapıdan **3-tab odaklı görünüme** indirgeyerek Home + Bütçe ekranları ile aynı tasarım dili (warm beige background, white cards, slate-blue brand, soft borders + shadows) altında birleştirmek. Power user özelliklerini (search, filter, bookmark) korumak ama görsel gürültüyü azaltmak.

EPIC8C-01 ile başlayan Home → Bütçe parity'sini Transactions'a taşıyarak app-wide visual coherence sağlamak. Bu, ADR-015 (Design Token Unification) önerisinin Transactions tarafında uygulanması.

## 2. Sponsor Decisions (Locked Pre-Mockup)

| # | Decision | Locked Value |
|---|---|---|
| 1 | Tab sayısı | **3 tab:** Liste / Takvim / Özet |
| 2 | Income color | **Success green** `#047857` light / `#34D399` dark |
| 3 | Search/Filter/Bookmark üst bar | **Hepsini tut**, temizlenmiş layout |

## 3. Information Architecture — Eski vs Yeni

### Eski (mevcut)

```
Transactions
├── Daily         (günlük liste)
├── Calendar      (ay ızgarası)
├── Monthly       (yıl > ay > hafta hierarchy)
├── Summary       (?)
└── Description   (?)
```

5 tab, decision fatigue, scan-and-pick davranışı zorlu.

### Yeni (önerilen)

```
Transactions
├── Liste (List)        ← default, %80 kullanım
│   ├── Day-grouped transaction rows
│   ├── Day total summary
│   └── Pull-to-search
│
├── Takvim (Calendar)   ← visual timeline
│   ├── Month grid
│   ├── Cell income/expense indicators
│   └── Tap day → liste'ye scroll-jump
│
└── Özet (Summary)      ← aggregated view
    ├── Hero metric (net total)
    ├── Income vs Expense bar
    ├── Top categories breakdown
    └── Week-by-week trend
```

3 tab, her tab tek bir mental model'e karşılık geliyor.

## 4. Design Tokens (EPIC8C-01'den miras)

### Light Mode

```
Background:      #F7F6F3   (warm beige page bg)
Surface:         #FFFFFF   (card bg)
Border:          #C8C4BC   (1px subtle)
Shadow:          0 2px 8px rgba(0,0,0,0.04)

Text Primary:    #1A1C24
Text Secondary:  #5C5E6B
Text Tertiary:   #8A90A8

Brand:           #3D5A99   (slate-blue)
Brand Variant:   #2E4A87   (darker, gradient stop)

Income:          #047857   (success green) ← YENİ
Expense:         #C0392B   (danger red)    ← mevcut
Total Positive:  #1A1C24   (text primary)  ← nötr siyah
Total Negative:  #C0392B   (danger red)    ← negatif kırmızı

Highlight Cell:  #EAEEF7   (calendar selected day bg)
```

### Dark Mode

```
Background:      #0F1117
Surface:         #181C27
Border:          #2E3453
Shadow:          0 2px 8px rgba(0,0,0,0.20)

Text Primary:    #F0F2F8
Text Secondary:  #8A90A8
Text Tertiary:   #5C5E6B

Brand:           #4F46E5
Brand Variant:   #3D5A99

Income:          #34D399   ← YENİ
Expense:         #E55A4E
Total Positive:  #F0F2F8
Total Negative:  #E55A4E

Highlight Cell:  #1F2540
```

### Spacing & Typography

```
Border Radius:
  - Card:        16px
  - Chip:        100px (full pill)
  - Input:       12px
  - FAB:         16px

Padding:
  - Card:        16px
  - Section gap: 24px
  - Row:         12px vertical, 16px horizontal

Typography:
  - Hero amount: 32px, weight 700
  - Card title:  17px, weight 600
  - Body:        15px, weight 400
  - Caption:     13px, weight 500
  - Section hdr: 12px, weight 600, uppercase, letter-spacing 0.5px
```

## 5. Screen-by-Screen Spec

### 5.1 Header (Common to All Tabs)

```
┌──────────────────────────────────────────┐
│  🔍   İşlemler           🔖    ☰        │  ← search, title, bookmark, filter
├──────────────────────────────────────────┤
│        ‹  Mayıs 2026  ›                  │  ← month navigator
├──────────────────────────────────────────┤
│  Liste │ Takvim │ Özet                   │  ← 3 tab
└──────────────────────────────────────────┘
```

**Header Refinements:**
- Title "İşlemler" / "Transactions" — sade, brand-bold
- 🔍 Search left-aligned, 🔖 Bookmark + ☰ Filter right-aligned
- Month navigator: subtle arrows, slate-blue active state
- Tab bar: 3 tab full-width, underline indicator (slate-blue)

### 5.2 Liste Tab (Default)

```
┌──────────────────────────────────────────┐
│  Income      Expense       Net           │
│  +1.000 €    −10 €         +990 €        │  ← summary strip
├──────────────────────────────────────────┤
│  8 Cuma                          +990 €  │  ← day header
│  ┌────────────────────────────────────┐  │
│  │ 💰  Maaş                           │  │
│  │     Dkb              +1.000,00 €  │  │  ← income row (green)
│  │ ────────────────────────────────  │  │
│  │ 🍜  Yemek                          │  │
│  │     Dkb                 −10,00 €  │  │  ← expense row (red)
│  └────────────────────────────────────┘  │
│                                          │
│  7 Perşembe                       0 €    │
│  ┌────────────────────────────────────┐  │
│  │  Bu gün işlem yok                  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
                                    [+]    ← FAB
```

**Detaylar:**
- Summary strip: 3 sütun (Income / Expense / Net), nötr typography, sade
- Day card: tek bir white container, içinde row'lar divider ile ayrılmış
- Day header: gün numarası slate-blue, gün ismi text-secondary
- Day total üst sağda: net rakam (income - expense)
- Empty days: "Bu gün işlem yok" placeholder (opsiyonel, default skip)
- Transaction row: emoji icon (32px circle bg muted) + category + account + amount

### 5.3 Takvim Tab

```
┌──────────────────────────────────────────┐
│  Income      Expense       Net           │
│  +1.000 €    −10 €         +990 €        │
├──────────────────────────────────────────┤
│  P  S  Ç  P  C  C  P                     │  ← weekday header
│ ─────────────────────────────────────    │
│  27 28 29 30  1  2  3                    │
│   4  5  6  7 [8] 9 10                    │  ← 8 highlighted (today + selected)
│             ↑                            │
│         +1K€ −10€                        │  ← cell amount indicator
│  11 12 13 14 15 16 17                    │
│  18 19 20 21 22 23 24                    │
│  25 26 27 28 29 30 31                    │
└──────────────────────────────────────────┘
```

**Detaylar:**
- Weekday header: tek satır, P/S/Ç/P/C/C/P (Pazartesi başlangıç)
- Hafta sonu rengi YOK (gereksiz görsel gürültü, sponsor kararı)
- Cell content: gün numarası + (varsa) amount indicators
- Active day: slate-blue daire, white text
- Today marker: subtle ring (brand color, transparent fill)
- Tap day → opsiyonel: bottom sheet ile o günün listesi (V1.x feature)

### 5.4 Özet Tab

```
┌──────────────────────────────────────────┐
│  ┌────────────────────────────────────┐  │
│  │ NET BU AY                 23 gün │  │
│  │                                    │  │
│  │      +990,00 €                     │  │  ← hero metric
│  │                                    │  │
│  │  +1.000 € gelir  −10 € gider       │  │  ← sub-text
│  └────────────────────────────────────┘  │
│                                          │
│  ÜST KATEGORİLER                         │
│  ┌────────────────────────────────────┐  │
│  │ 🍜 Yemek          ████░░░░ 100%   │  │
│  │                          10,00 €  │  │
│  │ ─────────────────────────────────  │  │
│  │ Sadece 1 kategoride harcama var    │  │  ← contextual hint
│  └────────────────────────────────────┘  │
│                                          │
│  HAFTA TRENDİ                            │
│  ┌────────────────────────────────────┐  │
│  │  ▁  ▁  █  ▁                        │  │  ← week bars
│  │  1  2  3  4                        │  │
│  │                                    │  │
│  │ En yoğun hafta: 4-10 Mayıs         │  │
│  │ +990,00 € net                      │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**Detaylar:**
- Hero card: brand gradient slate-blue (Bütçe hero card ile parite)
- Net total: büyük tipografi, beyaz text
- Sub-text: gelir + gider yan yana
- Top categories: max 5 kategori, progress bar, % + amount
- Week trend: bar chart, 4-5 hafta görünümü, en yoğun haftayı highlight

### 5.5 Empty State

```
┌──────────────────────────────────────────┐
│  Header (sade, tab bar yok)              │
├──────────────────────────────────────────┤
│                                          │
│            ╭─────────╮                   │
│            │   📋    │                   │  ← brand-tinted illustration
│            ╰─────────╯                   │
│                                          │
│        Henüz işlem yok                   │  ← headline
│                                          │
│   Gelir, gider veya transferi            │
│   ekleyerek başla                         │  ← subtitle
│                                          │
│   ┌──────────────────────────┐           │
│   │   + İlk işlemi ekle     │           │  ← brand CTA button
│   └──────────────────────────┘           │
│                                          │
└──────────────────────────────────────────┘
```

**Detaylar:**
- Illustration: brand-tinted circle bg + emoji/icon
- Headline: 20px, weight 600
- Subtitle: 15px, weight 400, text-secondary
- CTA: full-width-ish brand button, slate-blue, white text

### 5.6 Add Transaction Modal

```
┌──────────────────────────────────────────┐
│  ✕         Yeni İşlem                    │  ← close, title
├──────────────────────────────────────────┤
│                                          │
│  ┌─────────┬─────────┬─────────┐         │
│  │ Gider ✓ │  Gelir  │ Transfer│         │  ← segmented control
│  └─────────┴─────────┴─────────┘         │
│                                          │
│         0,00 €                           │  ← big amount input
│         ─────                            │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 🍜 Yemek    🚌 Ulaşım    🛒 Market │  │  ← quick category chips
│  └────────────────────────────────────┘  │  (4 most-used)
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ △ Kategori                      ›  │  │
│  ├────────────────────────────────────┤  │
│  │ ◫ Hesap                         ›  │  │
│  ├────────────────────────────────────┤  │
│  │ 📅 8 Mayıs 2026                 ›  │  │
│  ├────────────────────────────────────┤  │
│  │ ☰ Not (opsiyonel)                  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │           Kaydet                   │  │  ← primary CTA
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │      Kaydet & Devam                │  │  ← secondary CTA
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**Detaylar:**
- Big amount: 36px, weight 700, currency suffix sabit
- Quick chips: en son kullanılan 3-4 kategori (V1: most recent, V1.x: ML predicted)
- Form rows: tap-to-select pattern, white card grouped
- Date default "Bugün" — Bugün/Dün quick toggle olabilir (V1.x)

## 6. ARB Keys (Yaklaşık 30+ Yeni Key)

### Header
```
transactionsTitle: "İşlemler" / "Transactions"
transactionsSearchHint: "İşlemlerde ara" / "Search transactions"
transactionsFilterTitle: "Filtrele" / "Filter"
transactionsBookmarksTitle: "Yer İmleri" / "Bookmarks"
```

### Tabs
```
transactionsTabList: "Liste" / "List"
transactionsTabCalendar: "Takvim" / "Calendar"
transactionsTabSummary: "Özet" / "Summary"
```

### Summary Strip
```
transactionsStripIncome: "Gelir" / "Income"
transactionsStripExpense: "Gider" / "Expense"
transactionsStripNet: "Net" / "Net"
```

### List View
```
transactionsListEmptyDay: "Bu gün işlem yok" / "No transactions this day"
transactionsListDayTotal: "{net}" / "{net}"
```

### Calendar View
```
transactionsCalendarWeekdayMon: "P" / "M"
transactionsCalendarWeekdayTue: "S" / "T"
transactionsCalendarWeekdayWed: "Ç" / "W"
transactionsCalendarWeekdayThu: "P" / "T"
transactionsCalendarWeekdayFri: "C" / "F"
transactionsCalendarWeekdaySat: "C" / "S"
transactionsCalendarWeekdaySun: "P" / "S"
transactionsCalendarTodayMarker: "Bugün" / "Today"
```

### Summary View
```
transactionsSummaryHeroLabel: "NET BU AY" / "NET THIS MONTH"
transactionsSummaryHeroDaysLeft: "{n} gün kaldı" / "{n} days left"
transactionsSummaryHeroIncomeFooter: "{amount} gelir" / "{amount} income"
transactionsSummaryHeroExpenseFooter: "{amount} gider" / "{amount} expense"
transactionsSummaryTopCategoriesTitle: "ÜST KATEGORİLER" / "TOP CATEGORIES"
transactionsSummarySingleCategoryHint: "Sadece {n} kategoride harcama var" / "Only {n} category has spending"
transactionsSummaryWeekTrendTitle: "HAFTA TRENDİ" / "WEEK TREND"
transactionsSummaryWeekTrendBusiest: "En yoğun hafta: {range}" / "Busiest week: {range}"
transactionsSummaryWeekTrendNet: "{amount} net" / "{amount} net"
```

### Empty State
```
transactionsEmptyTitle: "Henüz işlem yok" / "No transactions yet"
transactionsEmptySubtitle: "Gelir, gider veya transferi ekleyerek başla" / "Start by adding income, expense, or transfer"
transactionsEmptyCTA: "İlk işlemi ekle" / "Add first transaction"
```

### Add Transaction Modal
```
transactionsAddTitle: "Yeni İşlem" / "New Transaction"
transactionsAddTypeExpense: "Gider" / "Expense"
transactionsAddTypeIncome: "Gelir" / "Income"
transactionsAddTypeTransfer: "Transfer" / "Transfer"
transactionsAddCategoryLabel: "Kategori" / "Category"
transactionsAddAccountLabel: "Hesap" / "Account"
transactionsAddDateLabel: "Tarih" / "Date"
transactionsAddNoteLabel: "Not (opsiyonel)" / "Note (optional)"
transactionsAddQuickChipsLabel: "Sık Kullanılan" / "Frequent"
transactionsAddSaveCTA: "Kaydet" / "Save"
transactionsAddSaveContinueCTA: "Kaydet & Devam" / "Save & Continue"
```

### Semantics (Accessibility)
```
transactionsRowSemanticIncome: "{amount} gelir, {category}, {account}" / "{amount} income, {category}, {account}"
transactionsRowSemanticExpense: "{amount} gider, {category}, {account}" / "{amount} expense, {category}, {account}"
transactionsCalendarCellSemanticDay: "{day} {month}, {income} gelir, {expense} gider" / "{day} {month}, {income} income, {expense} expense"
```

## 7. Open Questions (Sponsor Review Pending)

1. **Quick category chips kaynağı:** Most-used last 30 days mı, manuel pin mi? V1: most-used, V1.x: pinning option.
2. **Recurring transaction indicator:** Mockup'a dahil mi? Memory'mde recurring feature unknown. Sponsor kararı: V1.x'te ekle, EPIC8D-01 scope dışı.
3. **Bottom sheet day detail:** Calendar tap → bottom sheet mi, scroll-to-list mi? V1: scroll-to-list (basit), V1.x: bottom sheet.
4. **Bookmark feature:** Mevcut UI'da var, mantığı ne? "Favorite transactions" mı, "saved filter" mi? Sponsor PM ile teyit edilsin.
5. **Search scope:** Note text mı, category name mı, amount mı? V1: hepsi (full-text fuzzy).

## 8. ADR Impact

### ADR-015 Design Token Unification (Sprint 8d)
EPIC8D-01 ADR-015'in ilk büyük apply edilen test case'i. Transactions ekranı Home + Bütçe token'larını import edecek. Bu ADR'ın yazım scope'u Sprint 8d'ye dahil.

### ADR-016 Information Architecture (Yeni öneri)
5-tab → 3-tab geçişi bilinçli bir IA kararı. Future screen'ler (Stats, More) için emsal teşkil eder. Belki ADR-016 olarak formalize edilmeli — Sprint 8e'de değerlendirilir.

## 9. Migration Strategy

Mevcut Daily/Calendar/Monthly/Summary/Description tablarından 3-tab'a geçişte:
- **Daily** → **Liste** (tam karşılık)
- **Calendar** → **Takvim** (tam karşılık)
- **Monthly + Summary + Description** → **Özet** (3'ü 1'de birleşim)

Engineer için: Description tab'ının mevcut içeriği analiz edilmeli. Eğer kullanıcı-yazılı text özet ise, V1.x'te "Özet altında genişletilebilir bölüm" olarak ekle.

## 10. Acceptance Criteria

- [ ] Header: search + bookmark + filter ikonları temiz layout
- [ ] Tab bar: 3 tab, slate-blue underline indicator
- [ ] Summary strip: 3 sütun (gelir/gider/net), tab'lar arası tutarlı
- [ ] Liste tab: day-grouped cards, white surface, income green / expense red
- [ ] Takvim tab: weekday header (no weekend coloring), cell income/expense indicators, today marker
- [ ] Özet tab: hero card (brand gradient), top categories bar chart, week trend bars
- [ ] Empty state: illustration + headline + subtitle + brand CTA button
- [ ] Add Modal: big amount input, quick chips, form rows, dual CTA
- [ ] Light + Dark mode parity (Home + Bütçe token'larını kullan)
- [ ] All ARB keys EN + TR sponsor onaylı
- [ ] Card surface parity Home ↔ Bütçe ↔ Transactions (Bulgu #6 prevention)

## 11. Out of Scope (V1.x)

- Recurring transaction indicator
- Quick chip pinning
- Calendar tap → bottom sheet detail
- Description tab content (Özet'e taşındı, future enhancement)
- Bulk edit / multi-select
- Export to CSV/PDF
- Transaction templates

---

**Sponsor Approval Required Before Engineering:**
- [ ] Spec doc review
- [ ] All 6 mockup HTML files visual review
- [ ] ARB key list TR review
- [ ] Sprint 8d scope confirmation (5pt estimate)

---

*Last edited: 2026-05-08 by Sponsor (Burak)*
