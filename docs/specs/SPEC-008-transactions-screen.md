# SPEC-008: Transactions Screen (Ana Scaffold + Period Tab Bar)

**Sprint:** 4
**Related:** US-TransactionsViews (Sprint 4)
**Reference:** SPEC.md Section 9.1, Reference screenshots 17, 18, 19, 20
**Companion specs:** SPEC-009 (Daily), SPEC-010 (Calendar), SPEC-011 (Monthly), SPEC-012 (Summary)

---

## Purpose

`TransactionsScreen`, bottom navigation Tab 1'in root ekranıdır. Period tab bar aracılığıyla Daily, Calendar, Monthly ve Summary olmak üzere dört alt görünüm sunar. AppBar, MonthNavigator ve Income/Exp/Total özet çubuğu tüm alt görünümlerde ortak olarak bu scaffold tarafından yönetilir; yalnızca body bölgesi her alt görünüme göre değişir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│  [🔍]     Trans.     [🔖]  [≡•]      56dp  │  ← AppBar
├─────────────────────────────────────────────┤
│  [<]      Nisan 2026          [>]    48dp   │  ← MonthNavigator
├─────────────────────────────────────────────┤
│  Daily  Calendar  Monthly  Summary   49dp   │  ← PeriodTabBar
│             (aktif altında 2dp çizgi)        │
├─────────────────────────────────────────────┤
│  Income        Exp.          Total   60dp   │  ← IncomeSummaryBar
│  € 0,00     € 651,13       -651,13          │
├─────────────────────────────────────────────┤
│                                             │
│        [Aktif alt görünüm body]             │  ← PageView / IndexedStack
│      (Daily / Calendar / Monthly /          │
│             Summary)                        │
│                                             │
├─────────────────────────────────────────────┤
│  [Banner Ad — 50dp, sadece free tier]       │  ← AdBannerBar
├─────────────────────────────────────────────┤
│  [Bottom Tab Bar — 49dp]                    │
└─────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
TransactionsScreen (Scaffold)
├── AppBar
│   ├── Leading: SearchIconButton
│   ├── Title: Text "Trans."
│   └── Actions
│       ├── BookmarkIconButton
│       └── FilterIconButton
├── Column (body)
│   ├── MonthNavigator (48dp)
│   ├── PeriodTabBar (49dp)
│   ├── IncomeSummaryBar (60dp)
│   └── Expanded
│       └── PageView (veya IndexedStack)
│           ├── DailyView         (SPEC-009)
│           ├── CalendarView      (SPEC-010)
│           ├── MonthlyView       (SPEC-011)
│           └── SummaryView       (SPEC-012)
└── FloatingActionButton (Daily, Calendar, Summary tab'larında görünür)
    └── SecondaryFAB (Bookmark quick-add, Daily tab'da)
```

---

## Token Specs

### AppBar
| Element | Token |
|---------|-------|
| Height | 56dp (`AppHeights.appBar` + status bar safe area) |
| Background | `AppColors.bgPrimary` |
| Title text | `AppTypography.headline`, `AppColors.textPrimary` |
| Icon color | `AppColors.textSecondary` |
| Icon tap target | min 44x44dp |
| Leading icon | Phosphor `MagnifyingGlass` |
| Action 1 icon | Phosphor `BookmarkSimple` |
| Action 2 icon | Phosphor `SlidersHorizontal` |

### MonthNavigator
| Element | Token |
|---------|-------|
| Height | 48dp |
| Background | `AppColors.bgPrimary` |
| Arrow icons | Phosphor `CaretLeft` / `CaretRight`, `AppColors.textSecondary`, 24dp |
| Arrow tap target | 44x44dp |
| Month label | `AppTypography.title2`, `AppColors.textPrimary` |
| Label format | "Nisan 2026" (TR) / "April 2026" (EN) — `intl.DateFormat` |
| Label tap target | Min 100dp geniş, 44dp yüksek |
| Monthly sub-tab aktifken | Sadece yıl gösterilir: "2026" |

### PeriodTabBar
| Element | Token |
|---------|-------|
| Height | 49dp |
| Background | `AppColors.bgPrimary` |
| Tab label inaktif | `AppTypography.subhead`, `AppColors.textSecondary` |
| Tab label aktif | `AppTypography.subhead`, `AppColors.textPrimary` |
| Aktif alt çizgi | 2dp, `AppColors.brandPrimary`, tab genişliğinde |
| Alt çizgi animasyonu | 200ms, `Curves.easeInOut`, slide |
| Divider (tabın altı) | 1dp, `AppColors.divider` |
| Tab count | 4 (Daily, Calendar, Monthly, Summary) |
| Tab distribution | Equal flex (each: screen_width / 4) |

Tab sıraları ve i18n anahtarları:

| Index | Label (EN) | Label (TR) | i18n key |
|-------|-----------|-----------|---------|
| 0 | Daily | Günlük | `tab_daily` |
| 1 | Calendar | Takvim | `tab_calendar` |
| 2 | Monthly | Aylık | `tab_monthly` |
| 3 | Summary | Özet | `tab_summary` |

### IncomeSummaryBar
| Element | Token |
|---------|-------|
| Height | 60dp |
| Background | `AppColors.bgPrimary` |
| Bottom border | 1dp, `AppColors.divider` |
| Income label | `AppTypography.caption1`, `AppColors.textSecondary` |
| Income value | `AppTypography.moneySmall`, `AppColors.income` |
| Exp label | `AppTypography.caption1`, `AppColors.textSecondary` |
| Exp value | `AppTypography.moneySmall`, `AppColors.expense` |
| Total label | `AppTypography.caption1`, `AppColors.textSecondary` |
| Total value | `AppTypography.moneySmall`, `AppColors.textPrimary` |
| Total positive (+) | `AppColors.income` |
| Total negative (-) | `AppColors.expense` |
| Column distribution | Equal flex (1:1:1) |
| Column tap target | Full column, 60dp height |

### FAB (Floating Action Button)
| Element | Token |
|---------|-------|
| Primary FAB | 56dp circle, `AppColors.brandPrimary`, Phosphor `Plus` icon white 24dp |
| Secondary FAB | 44dp circle, `AppColors.bgSecondary`, Phosphor `BookmarkSimple` icon `AppColors.textSecondary` 20dp |
| FAB spacing | 8dp vertical between secondary and primary |
| FAB margin | 16dp right, 16dp bottom (above ad banner if visible) |
| Secondary FAB | Sadece Daily tab'da görünür |

### AdBannerBar
| Element | Token |
|---------|-------|
| Height | 50dp (`AppHeights.bannerAd`) |
| Görünürlük | `premiumStatus == 'free'` ise görünür |
| Background | `AppColors.bgSecondary` |

---

## States

### Default (İlk yükleme)
- Aktif tab: Daily (index 0) — `startScreen` settings key'e göre override edilebilir
- Aktif ay: Cihaz saatiyle mevcut ay
- IncomeSummaryBar: Mevcut ayın aggregate tutarları
- PageView/IndexedStack: DailyView yüklü, diğerleri lazy

### Loading
- IncomeSummaryBar değerleri yerine 3 adet `—` placeholder (textTertiary)
- Body bölgesinde `LoadingIndicator` merkezi
- MonthNavigator ok butonları disabled (opacity 0.5)

### Populated
- IncomeSummaryBar gerçek tutarları gösterir
- Aktif alt görünüm scrollable içeriğini gösterir
- FAB tüm sekmelerde görünür

### Empty (Seçili ayda hiç işlem yoksa)
- IncomeSummaryBar: 0,00 / 0,00 / 0,00
- Body bölgesi: her alt görünümün kendi empty state'i (bkz. SPEC-009–012)

### Error (Veri yükleme hatası)
- Body bölgesinde `EmptyStateView` ile hata mesajı
- Başlık: "Veriler yüklenemedi" / "Could not load data"
- Altyazı: "Lütfen tekrar deneyin." / "Please try again."
- CTA: "Tekrar Dene" / "Retry" butonu
- IncomeSummaryBar `—` gösterir

---

## Interactions

### Ay Navigasyonu
- `<` tıkla → aktif ay bir ay geriye gider, body ve summary bar yenilenir
- `>` tıkla → aktif ay bir ay ileriye gider; gelecek aya geçiş mümkün (bugünden ileri ay için işlem henüz yok olabilir)
- Ay label tıkla → `MonthYearPicker` bottom sheet açılır (Cupertino drum-roll, bgSecondary arka plan)
- Ay değiştikten sonra PageView/IndexedStack scroll pozisyonu sıfırlanır

### Tab Geçişi
- Tab tıklama → animasyonlu tab switch (200ms easeInOut)
- Horizontal swipe ile tab geçişi mümkün (`swipeAction` settings key `change_period` ise aktif; `change_date` ise swipe günü değiştirir — Daily view'e özel)
- Tab switch sırasında MonthNavigator ve IncomeSummaryBar aynı kalır

### IncomeSummaryBar Tıklama
- Income sütununa tap → DailyView'ü income-only filtresiyle göster
- Exp. sütununa tap → DailyView'ü expense-only filtresiyle göster
- Total sütununa tap → filtre temizlenir

### AppBar Aksiyonları
- Arama ikonu → SearchModal açılır (tam ekran overlay, tüm işlemlerde arama)
- Bookmark ikonu → BookmarkPickerModal açılır (bottom sheet)
- Filter ikonu → FilterModal açılır (bottom sheet, hesap/kategori/tarih aralığı filtresi)

### FAB
- Primary `+` tıkla → AddTransactionModal açılır (bkz. SPEC.md Section 9.2)
- Secondary Bookmark FAB tıkla → BookmarkPickerModal açılır

---

## MonthYearPicker (Alt Görünüm — Ortak)

```
┌─────────────────────────────────────────┐
│              Drag Handle                │  ← 4dp yüksek, 40dp geniş, bgTertiary
├─────────────────────────────────────────┤
│  Cancel              Done               │  ← 44dp high action row
├─────────────────────────────────────────┤
│                                         │
│  ◄  Ocak  Şubat  Mart  Nisan  ...  ►   │  ← Cupertino drum-roll, ay
│  ◄  2023    2024    2025    2026   ►   │  ← Cupertino drum-roll, yıl
│                                         │
└─────────────────────────────────────────┘
```

- Background: `AppColors.bgSecondary`
- "Done" → `AppColors.brandPrimary`, `AppTypography.headline`
- "Cancel" → `AppColors.textSecondary`, `AppTypography.headline`
- Seçim değiştikçe body preview yenilenmez (Done'a basılana kadar apply edilmez)

---

## Accessibility

| Element | Semantics Label |
|---------|----------------|
| Arama ikonu | "İşlemlerde ara" / "Search transactions" |
| Bookmark ikonu | "Yer imlerini aç" / "Open bookmarks" |
| Filter ikonu | "Filtrele" / "Filter transactions" |
| MonthNavigator `<` | "Önceki ay, [ay adı] [yıl]" / "Previous month, [month] [year]" |
| MonthNavigator `>` | "Sonraki ay, [ay adı] [yıl]" / "Next month, [month] [year]" |
| Ay label | "Geçerli dönem: [ay adı] [yıl]. Dönemi değiştirmek için dokunun." |
| Daily tab | "Günlük görünüm sekmesi. [Seçili/Seçilmedi]." |
| Calendar tab | "Takvim görünümü sekmesi. [Seçili/Seçilmedi]." |
| Monthly tab | "Aylık görünüm sekmesi. [Seçili/Seçilmedi]." |
| Summary tab | "Özet sekmesi. [Seçili/Seçilmedi]." |
| Income sütunu | "Toplam gelir: [tutar]" |
| Expense sütunu | "Toplam gider: [tutar]" |
| Total sütunu | "Net bakiye: [tutar]" |
| Primary FAB | "Yeni işlem ekle" / "Add new transaction" |
| Secondary FAB | "Yer iminden işlem ekle" / "Add from bookmark" |

- PeriodTabBar: `TabBar` semantics (Flutter native `TabBar` uygulaması zaten rol atar)
- Focus sırası: AppBar Leading → AppBar Actions (sol→sağ) → MonthNavigator < → Ay Label → MonthNavigator > → Tab 0 → Tab 1 → Tab 2 → Tab 3 → Body → FABs
- Dynamic Type: Tüm `AppTypography` tanımları `textScaleFactor`'ı kırpmaz; uzun ay isimleri MonthNavigator'da en az 2 karakter kısaltılır ("Nis 2026" gibi) gerekirse
- Kontrast: `textSecondary` (#B0B3B8) üzerine `bgPrimary` (#1A1B1E): ~7.5:1 — AA geçer

---

## i18n Keys

| Key | EN | TR |
|-----|----|----|
| `tab_daily` | Daily | Günlük |
| `tab_calendar` | Calendar | Takvim |
| `tab_monthly` | Monthly | Aylık |
| `tab_summary` | Summary | Özet |
| `transactions_title` | Trans. | İşlem |
| `income_label` | Income | Gelir |
| `expense_label` | Exp. | Gider |
| `total_label` | Total | Toplam |
| `error_load_title` | Could not load data | Veriler yüklenemedi |
| `error_load_subtitle` | Please try again. | Lütfen tekrar deneyin. |
| `retry_button` | Retry | Tekrar Dene |

---

## Edge Cases

| Durum | Davranış |
|-------|---------|
| Çok büyük tutar (> 999.999,99) | `CurrencyText` kısar: "€ 1,2M" formatı (milyonlar için); tabular figures korunur |
| Uzun para birimi sembolü | Symbol max 4 karakter, taşıyorsa `...` |
| Gelecek ay | Tüm tutarlar 0,00 gösterilir; empty state body görünür |
| Çok geçmiş ay (5+ yıl) | Normal çalışır, pagination yok |
| Aylık görünümde MonthNavigator | Sadece yıl gösterir ("2026"), navigasyon yıl bazlı |
| Hızlı tab değişimi sırasında data fetch | Debounce 100ms; son aktif sekmeye ait fetch öncelik alır, öncekiler iptal edilir |
| Offline mod | Lokal DB'den veri gelir; sync indicator gösterilmez (Faz 1'de cloud sync yok) |

---

## New Components (Sprint 4 — bu spec ile tanımlananlar)

Aşağıdaki bileşenler `COMPONENTS.md`'e eklenmelidir:

| Component | File | Used In | Notes |
|-----------|------|---------|-------|
| `MonthNavigator` | `features/transactions/presentation/widgets/month_navigator.dart` | SPEC-008, SPEC-009, SPEC-010, SPEC-011, SPEC-012, Stats screen | `currentMonth`, `onPrevious`, `onNext`, `onMonthTap` props. Monthly sub-tab modunda `showYearOnly: true`. |
| `PeriodTabBar` | `features/transactions/presentation/widgets/period_tabs.dart` | SPEC-008 | `tabs`, `activeIndex`, `onTabChanged`. Animasyonlu alt çizgi. |
| `IncomeSummaryBar` | `features/transactions/presentation/widgets/income_summary_bar.dart` | SPEC-008, SPEC-011 | `income`, `expense`, `total`, `currency`, `onIncomeTap`, `onExpenseTap`, `onTotalTap`. |

---

## Open Questions

1. **PageView vs. IndexedStack:** PageView tüm sekmeleri yükler (kaydırma UX güzel ama bellek maliyeti yüksek). IndexedStack lazy load için daha uygun. Flutter Engineer, sekme sayısı 4 olduğu için IndexedStack tercih edebilir — karar onlara bırakılır.
2. **Tab 1 label (bottom nav):** SPEC.md'de "28.4." (bugünün gün.ay) formatında dinamik. Bu bileşen `BottomTabScaffold`'a aittir, `TransactionsScreen`'e değil. Onay: değişiklik gerekmez.
3. **`swipeAction` ayarı:** `change_date` ise Daily view'de swipe günü değiştirir; `change_period` ise tab geçişi yapar. Bu davranışı Daily view (SPEC-009) ve Monthly view (SPEC-011) de etkileyebilir — koordinasyon gerekli.
4. **IncomeSummaryBar, Monthly tab'da:** Monthly sub-tab seçiliyken IncomeSummaryBar yıl bazlı mı, seçili dönem bazlı mı gösterilmeli? Karar: seçili yıl toplamını gösterir (MonthNavigator'da sadece yıl görünür).
5. **Filter state persistence:** Filtre uygulandığında AppBar filter ikonu üzerinde badge (nokta) gösterilmeli mi? Öneri: evet, 6dp kırmızı nokta — flutter-engineer onaylasın.
