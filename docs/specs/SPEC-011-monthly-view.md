# SPEC-011: Monthly View

**Sprint:** 4
**Related:** US-TransactionsViews (Sprint 4)
**Reference:** SPEC.md Section 9.1.7, Reference screenshot 18
**Parent scaffold:** SPEC-008 (TransactionsScreen)

---

## Purpose

Monthly View, bir yıl içindeki her ayı genişletilebilir kart yapısında listeler. Her ay, haftalık alt gruplara bölünmüş şekilde income/expense/total özetini gösterir. MonthNavigator yıl bazlı çalışır (ay değil, yıl navigasyonu). Bu görünüm yıllık bütçe takibi ve dönemsel karşılaştırma içindir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│  [MonthNavigator — YALNIZCA YIL: "2026"]   │  ← SPEC-008, showYearOnly: true
│  [PeriodTabBar — Monthly aktif]             │
│  [IncomeSummaryBar — yıl toplamı]           │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ April  1.4.~30.4.  €0  €651  -€651  │   │  ← MonthRow (genişletilmiş)
│  ├─────────────────────────────────────┤   │
│  │  27.4.~3.5.  € 0,00  € 53,95  -€53 │   │  ← WeekRow (hafta özeti)
│  │  20.4.~26.4. € 0,00  € 120,00 -€120│   │
│  │  13.4.~19.4. € 0,00  € 200,00 -€200│   │
│  │  6.4.~12.4.  € 0,00  € 160,00 -€160│   │
│  │  1.4.~5.4.   € 0,00  € 117,13 -€117│   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ March  1.3.~31.3.  €200  €300  -€100│   │  ← MonthRow (kapalı)
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ February  1.2.~28.2.  € 0  € 0  0  │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  [... Ocak'a kadar 12 ay]                   │
│                                             │
├─────────────────────────────────────────────┤
│  [AdBannerBar — free tier]                  │
└─────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
MonthlyView (ConsumerWidget)
└── Column
    ├── [IncomeSummaryBar — yıl toplamı, SPEC-008 bileşeni, showYearTotal: true]
    └── Expanded
        └── ListView.builder (12 MonthCard, Ocak → Aralık veya Aralık → Ocak)
            └── MonthCard (x12)
                ├── MonthRow (header, tappable — expand/collapse)
                └── AnimatedSize (expanded: WeekRows, collapsed: 0 height)
                    └── WeekRow (x N, haftaya göre)
```

---

## MonthNavigator (Yıl Modu)

Monthly View aktif olduğunda `MonthNavigator` yalnızca yıl gösterir:

```
  [<]       2026       [>]
```

- `<` → bir önceki yıl
- `>` → bir sonraki yıl
- Merkez label: `AppTypography.title2`, `AppColors.textPrimary`
- Label tap → YearPicker açılır (Cupertino drum-roll, sadece yıl)

---

## IncomeSummaryBar (Yıl Totalleri)

- SPEC-008'deki `IncomeSummaryBar` bileşeni; seçili yılın 12 aylık aggregate toplamını gösterir
- Label: "Income" / "Exp." / "Total" (aynı)
- Değerler: yıllık toplam

---

## MonthRow Spec

```
┌──────────────────────────────────────────────────────────────────────┐
│  [▶/▼]  April   1.4. ~ 30.4.      € 0,00   € 651,13   € -651,13    │
└──────────────────────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Satır yüksekliği | 52dp |
| Background (kapalı) | `AppColors.bgSecondary` |
| Background (açık) | `AppColors.bgTertiary` |
| Sol padding | `AppSpacing.lg` (16dp) |
| Sağ padding | `AppSpacing.lg` (16dp) |
| Genişletme oku | Phosphor `CaretRight` (kapalı) / `CaretDown` (açık), `AppColors.textTertiary`, 16dp |
| Ok ile metin arası | `AppSpacing.sm` (8dp) |
| Ay adı | `AppTypography.bodyMedium` (16px w500), `AppColors.textPrimary` |
| Ay adı genişliği | Sabit min 60dp |
| Tarih aralığı | `AppTypography.caption1` (12px), `AppColors.textTertiary`; format: "1.4. ~ 30.4." |
| Tarih aralığı sola hizalı | Ay adının sağında, 8dp boşluk |
| Income tutarı | `AppTypography.moneySmall`, `AppColors.income`, sağ köşe grubu içinde |
| Expense tutarı | `AppTypography.moneySmall`, `AppColors.expense` |
| Total tutarı | `AppTypography.moneySmall`, `AppColors.textPrimary` (pozitif) veya `AppColors.expense` (negatif) |
| Tutar arası boşluk | 8dp |
| Tüm satır tıklanabilir | expand/collapse toggle |
| Tap target | 52dp yükseklik, tam genişlik |
| Alt divider | 1dp, `AppColors.divider` |
| Genişletme animasyonu | 250ms, `Curves.easeInOut`, yükseklik + chevron dönüşü |
| Bugünün ayı (current month) | Sol kenar: 3dp `AppColors.brandPrimary` dikey çizgi |
| Boş ay (sıfır işlem) | Tutarlar "€ 0,00", stil aynı, expand edilebilir ama WeekRows boş |

---

## WeekRow Spec

```
┌──────────────────────────────────────────────────────────────────────┐
│       27.4. ~ 3.5.          € 0,00    € 53,95    € -53,95           │
└──────────────────────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Satır yüksekliği | 44dp |
| Background (normal) | `AppColors.bgSecondary` |
| Background (bugünün haftası) | `AppColors.bgTertiary` (hafif vurgu) |
| Sol padding | `AppSpacing.xl` (20dp) — MonthRow'dan daha içeride |
| Sağ padding | `AppSpacing.lg` (16dp) |
| Tarih aralığı | `AppTypography.caption1` (12px), `AppColors.textSecondary`; format: "27.4. ~ 3.5." |
| Tarih aralığı min genişliği | 100dp sabit (tutarların sağa hizalanması için) |
| Income | `AppTypography.moneySmall`, `AppColors.income` |
| Expense | `AppTypography.moneySmall`, `AppColors.expense` |
| Total | `AppTypography.moneySmall`, `AppColors.textPrimary` veya `AppColors.expense` |
| Tutar arası boşluk | 8dp |
| Alt divider | 1dp, `AppColors.divider` (son WeekRow'da MonthRow alt divider'ı kapsar) |
| Tüm satır tıklanabilir | Tap → DailyView'e geçiş, o haftanın ilk gününe scroll |
| Bugünün haftası vurgusu | `AppColors.brandPrimaryGlow` arka plan (0x33FF6B5C opacity) |

### Hafta Hesaplama Kuralı
- `weeklyStartDay` settings key'e göre (varsayılan: Monday)
- Ocak'ın 1'i Pazartesi değilse, o ay için ilk hafta kısmi olabilir ("1.4. ~ 5.4.")
- Son hafta da kısmi olabilir ("27.4. ~ 30.4.")
- Hafta aralıkları ayın sınırlarını aşabilir ("27.4. ~ 3.5.") — bu ayın işlemlerini içerir

---

## Month Card Expand/Collapse

| Durum | Davranış |
|-------|---------|
| İlk yükleme | Mevcut ay genişletilmiş, diğerleri kapalı |
| Tap MonthRow | Toggle expand/collapse |
| Birden fazla açık ay | İzin verilir (accordion değil, her ay bağımsız) |
| Scroll performance | `AnimatedSize` + `ListView.builder` ile lazy render |

---

## States

### Default
- Mevcut ay (Nisan 2026) expand edilmiş, diğerleri kapalı
- IncomeSummaryBar: seçili yılın toplamları
- Yıl: cihaz saat'inden hesaplanır

### Loading
- MonthRow'lar shimmer: ay adı, tarih, 3 tutar yerine shimmer kutular
- WeekRow'lar gösterilmez (henüz expand yok)

### Populated
- 12 MonthRow (Ocak-Aralık)
- Mevcut ay expanded

### Empty (Seçili yılda hiç işlem yok)
- 12 MonthRow gösterilir, hepsi "€ 0,00" ile
- Expand edilebilirler ama içeride WeekRow yoktur
- İlk açılışta mevcut ay expand edilmiş ve boş WeekRows yerine küçük bir mesaj: "Bu ayda işlem yok." (`AppTypography.caption1`, `AppColors.textTertiary`, sol indent 20dp, yükseklik 40dp)

### Error
- `EmptyStateView` (hata ikonu + metin + Retry)

---

## Interactions

### WeekRow Tap
- O haftanın ilk gününe ait DailyView'e navigate et
- Tab otomatik olarak "Daily"'ye geçer
- Aktif ay MonthNavigator'da güncellenir

### MonthRow Tap
- Expand/collapse toggle

### Yıl Navigasyonu
- `<` → önceki yıl; ay listesi yenilenir, mevcut aydaki ay expand edilir (eğer mevcut yıl ise), aksi hâlde en üst ay (Ocak)
- `>` → sonraki yıl; benzer davranış

---

## Accessibility

| Element | Semantics Label |
|---------|----------------|
| MonthRow (kapalı) | "Nisan 2026. Gelir: € 0,00, Gider: € 651,13, Toplam: -€ 651,13. Genişletmek için dokunun." |
| MonthRow (açık) | "Nisan 2026. Geliştirilmiş. Kapatmak için dokunun." |
| WeekRow | "27 Nisan – 3 Mayıs haftası. Gelir: € 0,00, Gider: € 53,95, Toplam: -€ 53,95. Günlük görünümde aç." |
| Bugünün haftası | "Bu hafta. 27 Nisan – 3 Mayıs. ..." prefix |
| IncomeSummaryBar | "2026 yılı toplamı. Gelir: [tutar], Gider: [tutar], Net: [tutar]" |
| MonthNavigator yıl | "Geçerli yıl: 2026" |

- Chevron ikon `ExcludeSemantics` içinde; expand durumu MonthRow semantics `hint` içinde
- Focus sırası: MonthNavigator → IncomeSummaryBar → MonthRow[0] → (expanded ise) WeekRow[0..N] → MonthRow[1] → ...
- `Semantics.expanded` property ile yardımcı teknoloji bildirimi

---

## Edge Cases

| Durum | Davranış |
|-------|---------|
| Yıl değiştiğinde expand state | Yeni yıla geçişte tüm aylar kapatılır, mevcut yıl ise mevcut ay açık |
| Şubat 28/29 gün | Hafta hesaplaması dinamik; 4 veya 5 WeekRow |
| Hafta birden fazla aya yayılıyorsa (örn. 27.4.~3.5.) | Sadece Nisan'daki günlerin tutarları gösterilir; "3.5." sadece tarih aralığı için |
| Çok büyük tutar (yıllık toplam) | "€ 1,2M" kısaltması |
| Gelecek aylar (Mayıs - Aralık 2026 için Nisan 2026'dayken) | Gösterilir, tutarlar 0,00; WeekRow'lar boş mesajla |
| Ocak ayı ilk günü Pazartesi değilse | İlk hafta kısmi ("1.1. ~ 5.1." gibi) |
| Aralık ayının son haftası yeni yıla taşıyorsa | "29.12. ~ 31.12." (ay sınırında kesilir) |
| Tek aylık tüm işlemler silinirse | MonthRow tutarları sıfırlanır, WeekRow'lar kaybolur |

---

## New Components (Bu spec ile tanımlananlar)

| Component | File | Notes |
|-----------|------|-------|
| `MonthCard` | `features/transactions/presentation/widgets/month_card.dart` | `monthData`, `isExpanded`, `isCurrentMonth`, `onToggle`, `onWeekTap` props. `AnimatedSize` ile genişleme. |
| `MonthRow` | `features/transactions/presentation/widgets/month_row.dart` | `month`, `dateRange`, `income`, `expense`, `total`, `isExpanded`, `isCurrentMonth`, `onTap`. |
| `WeekRow` | `features/transactions/presentation/widgets/week_row.dart` | `weekRange`, `income`, `expense`, `total`, `isCurrentWeek`, `onTap`. |

---

## Open Questions

1. **Hafta başlangıç günü:** WeekRow tarih aralıkları `weeklyStartDay` settings key'e göre dinamik mi, yoksa sabit Pazartesi mi? Bu spec: dinamik — flutter-engineer `WeekRow` bileşenini settings'den okuyarak hesaplar.
2. **WeekRow tap → DailyView navigate:** Tab geçişi ani mi, animasyonlu mu? Öneri: 200ms easeInOut tab geçişi, ardından DailyView ilgili güne scroll.
3. **Birden fazla ay aynı anda expand edilebilir mi?** Bu spec'te: evet (bağımsız toggle). Eğer PM accordion davranışı isterse: aynı anda yalnızca bir ay açık. Kararı PM verir.
4. **Gelecek aylar gösterilmeli mi?** Bu spec'te: evet, 0,00 ile gösterilir. Eğer PM gizlenmesini isterse: yalnızca işlem olan aylar + cari ay.
5. **Yıl IncomeSummaryBar'ı:** Seçili yılın tüm 12 aylık toplamı mı, yoksa yalnızca geçmiş + cari ayın toplamı mı? Bu spec: tüm 12 ay (bütçe planlama için).
