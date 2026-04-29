# SPEC-009: Daily View

**Sprint:** 4
**Related:** US-TransactionsViews (Sprint 4)
**Reference:** SPEC.md Section 9.1.5, Reference screenshot 20
**Parent scaffold:** SPEC-008 (TransactionsScreen)

---

## Purpose

Daily View, seçili ayın günlere göre gruplu işlem listesini gösterir. Her gün için bir başlık satırı ve o gün altında işlem satırları yer alır. Kullanıcı günlük harcama/gelirlerin detayını görür, işlem üzerinde swipe-to-delete veya swipe-to-edit yapabilir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│  [MonthNavigator]                           │  ← SPEC-008'den gelir (shared)
│  [PeriodTabBar — Daily aktif]               │
│  [IncomeSummaryBar]                         │
├─────────────────────────────────────────────┤
│                                             │
│  ── 27   Mon ──────── € 0,00  € 53,95 ──   │  ← DayHeaderRow (56dp)
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ [emoji] Food      Bank Accounts   € 53,95 │  ← TransactionRow (56dp)
│  │         Restaurant (Every Month)        │
│  └──────────────────────────────────────┘   │
│                                             │
│  ── 26   Sun ──────── € 0,00  € 120,00 ──  │  ← DayHeaderRow
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ [emoji] Bills     Cash            € 120,00│
│  │         Utilities                       │
│  └──────────────────────────────────────┘   │
│                                             │
│  ── 25   Sat ──── Sadece gelir → mavi ────  │
│  ┌──────────────────────────────────────┐   │
│  │ [emoji] Salary    Debit Card    € 3.200,00│
│  └──────────────────────────────────────┘   │
│                                             │
│            [Boş alan / daha eski günler]    │
│                                             │
├─────────────────────────────────────────────┤
│  [AdBannerBar — free tier]                  │
└─────────────────────────────────────────────┘

Sağ alt (z-layer üstünde):
  ┌──────┐   ← SecondaryFAB (44dp, Bookmark)
  ┌──────┐   ← PrimaryFAB (56dp, +)
```

---

## Component Hierarchy

```
DailyView (StatefulWidget / ConsumerWidget)
└── CustomScrollView (veya ListView.builder)
    ├── SliverList
    │   ├── [Day Group 1]
    │   │   ├── DayHeaderRow
    │   │   └── TransactionRow (x N)
    │   ├── [Day Group 2]
    │   │   ├── DayHeaderRow
    │   │   └── TransactionRow (x N)
    │   └── ...
    └── SliverPadding (bottom: FAB + AdBanner yüksekliği)
```

---

## DayHeaderRow Spec

```
┌─────────────────────────────────────────────┐
│ 27  [Mon]                  € 0,00  € 53,95  │
└─────────────────────────────────────────────┘
```

| Element | Token / Değer |
|---------|--------------|
| Satır yüksekliği | 56dp |
| Satır background | `AppColors.bgPrimary` |
| Sol padding | `AppSpacing.lg` (16dp) |
| Sağ padding | `AppSpacing.lg` (16dp) |
| Gün numarası | `AppTypography.title1` (28px w700), `AppColors.textPrimary` |
| Gün numarası genişliği | 36dp sabit |
| Gün rozeti (label) | `AppTypography.caption2` (11px), 20x18dp, `AppRadius.sm` (6dp), padding 4dp horizontal |
| Hafta içi rozet bg | `AppColors.bgTertiary` |
| Hafta içi rozet text | `AppColors.textSecondary` |
| Cumartesi rozet bg | `AppColors.income` (mavi) opacity 0.15 |
| Cumartesi rozet text | `AppColors.income` |
| Pazar rozet bg | `AppColors.expense` opacity 0.15 |
| Pazar rozet text | `AppColors.expense` |
| Bugün vurgusu | Gün numarası `AppColors.bgTertiary` daire içinde (32dp circle) |
| Income tutarı (sağ) | `AppTypography.moneySmall`, `AppColors.income`, "€ 0,00" |
| Expense tutarı (sağ) | `AppTypography.moneySmall`, `AppColors.expense`, "€ 53,95" |
| Sıfır tutar görünümü | Her iki tür de gösterilir; değer `AppColors.textTertiary` olur sıfırsa |
| Tutar arası boşluk | 8dp |
| İnce divider | Alt kısımda 1dp, `AppColors.divider` |

---

## TransactionRow Spec

```
┌──────────────────────────────────────────────────────┐
│  [CategoryIcon]  [Category Name]  [Account + Note]  [Amount]  │
│  40dp            textSecondary     textTertiary      moneySmall│
│                  headline size     caption1                    │
└──────────────────────────────────────────────────────┘
```

| Element | Token / Değer |
|---------|--------------|
| Satır yüksekliği | 56dp (`AppHeights.listItem`) |
| Satır background | `AppColors.bgPrimary` |
| Sol padding | `AppSpacing.lg` (16dp) |
| Sağ padding | `AppSpacing.lg` (16dp) |
| Bölümler arası vertical divider | Yok; yalnızca alt ince divider |
| Alt divider | 1dp, `AppColors.divider`, sol 72dp indent'li (ikon sonrası) |
| **Sol — CategoryIcon** | 40dp circle, kategori rengi (colorHex), emoji 20dp içinde |
| Icon ile metin arası boşluk | `AppSpacing.md` (12dp) |
| **Orta — üst satır** | Kategori adı: `AppTypography.bodyMedium` (16px w500), `AppColors.textPrimary` |
| **Orta — alt satır** | Hesap adı + tekrar bilgisi: `AppTypography.caption1` (12px), `AppColors.textTertiary` |
| Tekrar sembolü | Phosphor `ArrowClockwise` 12dp önce hesap adı |
| Transfer simgesi | Phosphor `ArrowsLeftRight` 12dp; "Hesap1 → Hesap2" formatı |
| **Sağ — tutar** | `AppTypography.moneySmall` (15px w500, tabular figs) |
| Expense tutarı rengi | `AppColors.expense` (coral) |
| Income tutarı rengi | `AppColors.income` (mavi) |
| Transfer tutarı rengi | `AppColors.textPrimary` (beyaz) |
| Subcategory gösterimi | Kategori adının altına küçük `AppTypography.caption2`, `AppColors.textTertiary` |
| isExcluded işlem | Tutar üzerinde strikethrough + `AppColors.textTertiary` rengi |
| Tüm satır tap target | Min 44dp yüksek (56dp zaten karşılar) |

---

## Swipe Actions

### iOS: Swipe Gesture (Dismissible benzeri)

**Sola kaydır (Trailing actions):**
```
┌────────────────────────────────┬──────────┬──────────┐
│        [işlem içeriği]         │  [Edit]  │ [Delete] │
│                                │  48x56dp │  64x56dp │
└────────────────────────────────┴──────────┴──────────┘
```

| Aksiyon | Arka plan | İkon | Label | Genişlik |
|---------|-----------|------|-------|---------|
| Edit | `AppColors.bgTertiary` | Phosphor `PencilSimple`, white | "Edit" / "Düzenle" | 64dp |
| Delete | `AppColors.error` | Phosphor `TrashSimple`, white | "Delete" / "Sil" | 80dp |

- Tam sola sürükleme (>80% genişlik) → Delete aksiyonu tetiklenir
- Edit tap → AddTransactionModal, pre-populated
- Delete tap → confirmation dialog (aşağıya bkz.)

**Sağa kaydır (Leading action):**
- Yok (referans uygulamada leading swipe mevcut değil)

### Android: Long-Press Context Menu
- Long press → Context menu (BottomSheet veya PopupMenuButton)
- Seçenekler: "Düzenle" / "Sil" / "İptal"

---

## Delete Confirmation Dialog

```
┌───────────────────────────────────────┐
│          İşlemi Sil?                  │
│                                       │
│  Bu işlem kalıcı olarak silinecek.    │
│  Bu işlem geri alınamaz.              │
│                                       │
│     [İptal]         [Sil]            │
└───────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Dialog background | `AppColors.bgSecondary` |
| Başlık | `AppTypography.headline`, `AppColors.textPrimary` |
| Açıklama | `AppTypography.subhead`, `AppColors.textSecondary` |
| "İptal" | `AppButton` ghost, `AppColors.textSecondary` |
| "Sil" | `AppButton` primary, `AppColors.error` rengi (filled) |
| Dialog radius | `AppRadius.lg` (16dp) |

---

## Interaction: Gün Başlığına Tap
- Tüm günün detayını zaten görüyoruz; ayrı tap aksiyonu yok.
- Gün başlığı satırı tap-interactive değil (tap target yok, sadece görsel divider).

## Interaction: TransactionRow Tap
- Tap → `TransactionDetailScreen` push (veya AddTransactionModal edit modunda)
- Not: SPEC.md'ye göre AddTransactionModal pre-populated açılır (edit mode)

## Interaction: FAB Tap
- Primary FAB → AddTransactionModal açılır (tarih: aktif olan gün, önce en üstteki gün)
- Secondary FAB → BookmarkPickerModal açılır

---

## Empty State

```
┌─────────────────────────────────────────────┐
│                                             │
│              [İllüstrasyon]                 │
│           (Boş defter görseli)              │
│                                             │
│         Henüz işlem eklenmedi.              │
│   Gelir, gider veya transfer kaydı          │
│            oluşturmak için                  │
│          + butonuna dokunun.                │
│                                             │
│         [ + İşlem Ekle ]                   │  ← AppButton primary
│                                             │
└─────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Container | `EmptyStateView` (core/widgets) |
| Illustration | Monochrome, `AppColors.textTertiary` tint, ~120dp |
| Başlık | `AppTypography.title3`, `AppColors.textPrimary` |
| Altyazı | `AppTypography.subhead`, `AppColors.textSecondary` |
| CTA | `AppButton` primary, "İşlem Ekle" / "Add Transaction" |

i18n keys: `daily_empty_title`, `daily_empty_subtitle`, `daily_empty_cta`

---

## Loading State
- Her gün grubu için, gerçek satırlar yerine 3 adet shimmer satır (56dp, gradient)
- Shimmer renkleri: `AppColors.bgSecondary` → `AppColors.bgTertiary`
- DayHeaderRow'da tutarlar yerine 60dp geniş, 14dp yüksek shimmer kutusu

---

## Error State
- `EmptyStateView` bileşeni, hata ikonu ile
- Başlık: "İşlemler yüklenemedi" / "Could not load transactions"
- CTA: "Tekrar Dene" / "Retry"

---

## Sorting & Grouping Logic

- İşlemler tarih DESC sıralıdır (en yeni gün en üstte)
- Aynı gün içindeki işlemler `createdAt DESC` sıralıdır
- Her gün yalnızca o günde en az 1 işlem varsa DayHeaderRow gösterilir
- Gelecekteki günler (today+1 ve ötesi) gösterilmez

---

## Accessibility

| Element | Semantics Label |
|---------|----------------|
| DayHeaderRow | "27 Nisan, Pazartesi. Gelir: [tutar], Gider: [tutar]" |
| TransactionRow | "[Kategori adı], [hesap adı], [tutar]. Düzenlemek için çift dokunun." |
| Delete swipe action | "Sil" |
| Edit swipe action | "Düzenle" |
| Primary FAB | "Yeni işlem ekle" |
| Secondary FAB | "Yer iminden işlem ekle" |

- `TransactionRow` için `ExcludeSemantics` uygulanmaz; tüm satır semantik node olmalı
- Screen reader odağı: DayHeaderRow → TransactionRow(1) → TransactionRow(N) → sonraki DayHeaderRow
- Swipe actions Android'de long-press semantic action olarak expose edilmeli

---

## Edge Cases

| Durum | Davranış |
|-------|---------|
| Çok uzun kategori/hesap adı | Orta sütun `maxLines: 1`, overflow: ellipsis |
| Çok büyük tutar | `CurrencyText` kısar (>999.999 → "€ 1,2M") |
| Aynı günde 50+ işlem | `ListView.builder` ile lazy rendering; performans sorunsuz |
| Seçili ay = current month | Bugünden sonraki günler gösterilmez |
| Seçili ay = geçmiş ay | Tüm günler (1-30/31) gösterilir |
| Transfer işlemi | İkon: iki ok, renk beyaz, alt satır "Hesap1 → Hesap2" |
| isExcluded = true | Tutar strikethrough, `AppColors.textTertiary`, satır hafif dim |
| Recurring işlem | Hesap adı sonrası "(Her Ay)" / "(Every Month)" italik |
| Aynı gün içinde önce income sonra expense | Sıra `createdAt DESC`; mix gösterim renk ile ayrışır |
| Filtre uygulandıysa (IncomeSummaryBar tap) | Sadece o tipe ait işlemler gösterilir; DayHeaderRow'daki karşı tür tutar gizlenir |

---

## Open Questions

1. **TransactionRow tap davranışı:** Detay ekranı mı, yoksa doğrudan AddTransactionModal edit modu mu açılacak? Referans uygulamaya göre edit modal tercih edilir — PM onayı bekleniyor.
2. **Aynı gün için DayHeaderRow'da tarih formatı:** "27 Mon" mü, "27 Pzt" mı? i18n'e göre otomatik; ancak abreviation uzunluğu (3 vs 2 karakter) flutter-engineer onaylamalı.
3. **`swipeAction = change_date`:** Daily view'da yatay swipe, günü değiştirir mi (sonraki/önceki güne atlar) yoksa standart liste scroll'u mu olur? Karar: PM + flutter-engineer koordineli almalı. Bu spec'te: swipe liste scroll olarak bırakıldı; `change_date` ayarı için ayrı gesture detector entegrasyonu gerekebilir.
