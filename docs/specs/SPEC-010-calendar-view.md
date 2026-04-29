# SPEC-010: Calendar View

**Sprint:** 4
**Related:** US-TransactionsViews (Sprint 4)
**Reference:** SPEC.md Section 9.1.6, Reference screenshot 19
**Parent scaffold:** SPEC-008 (TransactionsScreen)

---

## Purpose

Calendar View, seçili aya ait işlemleri aylık takvim grid formatında gösterir. Her gün hücresi o güne ait harcama/gelir tutarlarını küçük badge olarak sunar. Bir güne dokunulduğunda o günün işlemleri aşağıdan bir panel olarak açılır.

---

## Layout — Genel

```
┌─────────────────────────────────────────────┐
│  [MonthNavigator]                           │  ← SPEC-008'den
│  [PeriodTabBar — Calendar aktif]            │
│  [IncomeSummaryBar]                         │
├─────────────────────────────────────────────┤
│  Mon  Tue  Wed  Thu  Fri  Sat  Sun   32dp   │  ← WeekDayHeader
├─────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐    │
│ │  [Hücre][Hücre][Hücre][...][Hücre]  │    │
│ │  [Hücre][Hücre][Hücre][...][Hücre]  │    │  ← CalendarGrid (her satır ~72dp)
│ │  [Hücre][Hücre][Hücre][...][Hücre]  │    │
│ │  [Hücre][Hücre][Hücre][...][Hücre]  │    │
│ │  [Hücre][Hücre][Hücre][...][Hücre]  │    │
│ └──────────────────────────────────────┘    │
├─────────────────────────────────────────────┤
│  [Seçili gün işlem listesi — DayDetailPanel]│  ← Collapsible, 0dp iken gizli
│  (aşağıdan slide-in, max ~50% ekran)        │
├─────────────────────────────────────────────┤
│  [AdBannerBar — free tier]                  │
└─────────────────────────────────────────────┘

Sağ alt (z-layer):
  ┌──────┐  ← PrimaryFAB (56dp, +)
```

---

## WeekDayHeader Spec

```
┌──────────────────────────────────────────────────────┐
│  Mon    Tue    Wed    Thu    Fri     Sat     Sun      │
│ (gri)  (gri)  (gri)  (gri)  (gri)  (mavi)  (kırmızı)│
└──────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Satır yüksekliği | 32dp |
| Background | `AppColors.bgPrimary` |
| Alt border | 1dp, `AppColors.divider` |
| Hafta içi (Mon-Fri) | `AppTypography.caption1`, `AppColors.textSecondary` |
| Cumartesi | `AppTypography.caption1`, `AppColors.income` (mavi) |
| Pazar | `AppTypography.caption1`, `AppColors.expense` (coral) |
| Hizalama | Her sütun ortada, hücre genişliğine eşit |
| i18n | `intl.DateFormat('EEE')` ile hafta günü kısaltması; dil ayarına göre |

---

## CalendarGrid Spec

### Hücre Boyutları

| Element | Değer |
|---------|-------|
| Hücre genişliği | `screen_width / 7` |
| Hücre yüksekliği | ~72dp (ekranda 5 satır olunca toplam ~360dp grid) |
| Hücre iç padding | 2dp her yönden |
| Izgara satır ayrımı | 1dp `AppColors.divider` |
| Izgara sütun ayrımı | Yok (bitişik) |

### Hücre İçi Layout

```
┌─────────────────┐
│  27             │  ← Gün numarası (sol üst)
│                 │
│  € 198,44       │  ← Gider tutarı (alt, coral)
│  € 3.200,00     │  ← Gelir tutarı (alt, mavi) — varsa
└─────────────────┘
```

| Element | Token |
|---------|-------|
| Gün numarası | `AppTypography.caption1` (12px), `AppColors.textPrimary` |
| Gün numarası padding | 2dp üst, 4dp sol |
| Bugünün numarası | 22dp circle, `AppColors.brandPrimary` dolu, `AppColors.textOnBrand` |
| Seçili günün numarası | 22dp circle, `AppColors.bgTertiary` dolu, `AppColors.textPrimary`; seçili ise `brandPrimary` border 2dp |
| Önceki/sonraki ay günleri | `AppColors.textTertiary` gün numarası; tutar gösterilmez |
| Gider tutarı | `AppTypography.caption2` (11px), `AppColors.expense` |
| Gelir tutarı | `AppTypography.caption2` (11px), `AppColors.income` |
| Tutar hizalama | Alt-orta (center-bottom) |
| Tutar boşluk | Her iki satır arası 1dp |
| Sadece gider varsa | Tek satır gider (coral) |
| Sadece gelir varsa | Tek satır gelir (mavi) |
| İkisi de varsa | Üstte gelir (mavi), altta gider (coral) |
| Hiç işlem yoksa | Tutar gösterilmez; hücre boş görünür |
| Hücre tap target | Hücrenin tamamı (genellikle ≥44dp geniş ve 72dp yüksek — karşılanır) |
| Seçili hücre background | `AppColors.bgTertiary` |
| Seçilmemiş + işlem olan hücre | Hafif `AppColors.brandPrimaryGlow` arka plan tonu (0x33FF6B5C) — opsiyonel, referans uygulamaya bakılarak karar verilir |

### Tutar Formatlama (Hücre İçi)

- Tutar < 1.000: "€ 53,95" (tam)
- 1.000 ≤ tutar < 10.000: "€ 1,2K"
- tutar ≥ 10.000: "€ 12K"
- Sembol ve kısaltma arasında boşluk yok: "€12K"

---

## DayDetailPanel (Seçili Gün İşlem Listesi)

Bir güne dokunulduğunda CalendarGrid'in altında, AdBannerBar'ın üzerinde aşağıdan slide-in bir panel açılır.

```
┌─────────────────────────────────────────────┐
│  ── Nisan 27, Pazartesi ──       [X kapat] │  ← Panel başlığı (48dp)
├─────────────────────────────────────────────┤
│  [TransactionRow #1 — SPEC-009 ile aynı]   │
│  [TransactionRow #2]                        │
│  [TransactionRow #3]                        │
│  [...]                                      │
└─────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Panel background | `AppColors.bgSecondary` |
| Panel top radius | `AppRadius.xl` (24dp) |
| Panel başlık yüksekliği | 48dp |
| Başlık metni | `AppTypography.headline`, `AppColors.textPrimary` |
| Tarih formatı | "27 Nisan, Pazartesi" / "April 27, Monday" |
| Kapat ikonu | Phosphor `X`, `AppColors.textSecondary`, 20dp, sağda 16dp margin |
| Kapat tap target | 44x44dp |
| Panel max yükseklik | `screen_height * 0.5` |
| Panel min yükseklik | 48dp (başlık) + en az 1 TransactionRow = 104dp |
| İçerik: TransactionRow | `SPEC-009` ile tamamen aynı bileşen |
| İçerik kaydırılabilirlik | Scrollable (ListView) |
| Swipe-to-delete | SPEC-009 ile aynı davranış (aynı bileşen) |
| Panel açılış animasyonu | 250ms, `Curves.easeOutCubic`, aşağıdan yukarı slide |
| Panel kapanış animasyonu | 200ms, `Curves.easeInCubic`, yukarıdan aşağı slide |

### Panel Açılma Tetikleyiciler
1. Takvim hücresine tap
2. Daha önce seçili bir güne tekrar tap → panel kapanır (toggle)
3. Kapat ikonuna tap → panel kapanır
4. Başka bir güne tap → panel güncellenir (içerik değişir, slide animasyonla)
5. Swipe down on panel → panel kapanır

### Panel Boş State

```
┌─────────────────────────────────────────────┐
│  ── Nisan 15, Çarşamba ──       [X kapat]  │
├─────────────────────────────────────────────┤
│         Bu gün için işlem yok.              │
│      + butonuna dokunarak ekleyin.          │
└─────────────────────────────────────────────┘
```

- Panel açık kalır (kapanmaz), boş state mesajı gösterilir
- Açıklama: `AppTypography.subhead`, `AppColors.textSecondary`
- Panel yüksekliği: min (başlık + 80dp boş state içeriği)

---

## Interactions

### Ay Değişimi
- MonthNavigator `<` / `>` → CalendarGrid yeni aya animate edilir (200ms fade+slide)
- Yeni ayda seçili gün yoktur (DayDetailPanel kapanır)
- DayDetailPanel eğer açıksa: ay değiştiğinde panel kapanır

### Bugüne Kaydırma
- CalendarView ilk açıldığında veya ay değiştirildiğinde bugünü içeren hafta satırı görünümde olmalı (scroll to today)
- Geçmiş ay görüntüleniyorsa ilk satır görünür (scroll sıfırda)

### FAB
- Primary FAB tap → AddTransactionModal açılır
- Tarih: seçili gün varsa o gün, yoksa bugün

---

## States

### Default (Ay ilk yüklendiğinde)
- Bugünün hücresi vurgulanmış (brandPrimary circle)
- Seçili hücre yok → DayDetailPanel kapalı
- CalendarGrid tüm günlerle gösterilir
- İşlem olan hücreler tutarlarıyla görünür

### Loading
- CalendarGrid: Her hücrede gün numarası görünür, tutar yerine shimmer (küçük 30x8dp kutu)
- DayDetailPanel açıksa: shimmer TransactionRow'lar (3 adet)

### Populated
- Normal görünüm

### Empty (Seçili ayda hiç işlem yok)
- CalendarGrid gösterilir ama tüm hücreler boş (tutar yok)
- DayDetailPanel kapalı
- CalendarGrid üzerinde `EmptyStateView` overlay gösterilmez (grid her zaman görünür)
- IncomeSummaryBar 0,00 / 0,00 / 0,00

### Error
- CalendarGrid yerine `EmptyStateView` (hata ikonu + "Veriler yüklenemedi" + Retry)

---

## Accessibility

| Element | Semantics Label |
|---------|----------------|
| WeekDayHeader her sütun | "Pazartesi" / "Monday" (kısaltma değil, tam ad) |
| CalendarCell (işlemsiz) | "15 Nisan. İşlem yok." |
| CalendarCell (işlemli) | "27 Nisan, Pazartesi. Gider: € 53,95, Gelir: € 0,00. Günün işlemlerini görmek için dokunun." |
| CalendarCell (önceki/sonraki ay) | "28 Mart. Farklı ay." — tap aksiyonu yok |
| Bugün hücresi | "Bugün, 29 Nisan." prefix ile |
| Seçili hücre | "Seçili. 27 Nisan." |
| Panel başlığı | "27 Nisan, Pazartesi işlemleri" |
| Panel kapat butonu | "Günlük paneli kapat" |
| FAB | "Yeni işlem ekle" |

- CalendarGrid için `GridView` semantics: Her hücre ayrı `Semantics` node
- Panel açıkken focus, panel içindeki TransactionRow'lara geçer
- Panel kapandığında focus seçili hücreye döner
- Klavye navigasyonu: ok tuşları ile hücreler arası geçiş (iOS Bluetooth klavye, Android accessibility)

---

## Edge Cases

| Durum | Davranış |
|-------|---------|
| Ay 28 gün (Şubat) | Grid 4 satır; kalan alan boş veya sonraki aya ait soluk günler |
| Ay 29, 30, 31 gün | Grid 4 veya 5 satır |
| Hücrede çok büyük tutar | Kısaltma: "€12K", "€1,2M" |
| Hücrede çok fazla işlem | Panel scroll edilebilir; max 50 işlem göster, altında "Daha fazla" (MVP'de hepsini göster) |
| Seçili gün değiştirildi (tap başka güne) | Panel içeriği animate ederek yeni güne geçer |
| Gelecek güne tap (bugünden sonra) | Boş panel açılır; FAB tüm sekmelerden erişilebilir |
| Önceki/sonraki ay günlerine tap | Tap aksiyonu yok (disabled); semantics "Farklı ay" |
| Çok uzun ay geçişi animasyonu sırasında hızlı tap | Debounce 100ms; son seçili gün state doğru kalır |
| Panel açıkken ay değiştirilirse | Panel kapanır, yeni aya geçilir |

---

## Animation Summary

| Animasyon | Süre | Eğri | Ne Animate Eder |
|-----------|------|------|----------------|
| Hücre seçimi | 150ms | `Curves.easeInOut` | Arka plan rengi fade |
| Panel açılış | 250ms | `Curves.easeOutCubic` | Yükseklik + opacity |
| Panel kapanış | 200ms | `Curves.easeInCubic` | Yükseklik + opacity |
| Ay geçişi (grid) | 200ms | `Curves.easeInOut` | Horizontal slide (sol veya sağ) |
| Panel içerik güncelleme | 150ms | `Curves.easeInOut` | Fade + vertical micro-slide |

---

## New Components (Bu spec ile tanımlananlar)

| Component | File | Notes |
|-----------|------|-------|
| `CalendarGrid` | `features/transactions/presentation/widgets/calendar_grid.dart` | `month`, `transactionSummaryByDay` (Map<DateTime, DaySummary>), `selectedDay`, `onDaySelected` props. 7-kolon grid. |
| `CalendarDayCell` | `features/transactions/presentation/widgets/calendar_day_cell.dart` | `day`, `isCurrentMonth`, `isToday`, `isSelected`, `income`, `expense`, `onTap`. |
| `DayDetailPanel` | `features/transactions/presentation/widgets/day_detail_panel.dart` | `selectedDay`, `transactions`, `onClose`, `onTransactionTap`, `onTransactionDelete`. Animated height. |

---

## Open Questions

1. **Önceki/sonraki ay günlerine tap:** Tıklanınca o aya geçiş yapılsın mı? Referans uygulama geçiş yapar. Öneri: evet, MonthNavigator'ı otomatik değiştirir — PM onayı bekleniyor.
2. **Panel drag-to-resize:** Kullanıcı paneli yukarı sürükleyerek büyütebilir mi? Sprint 4'te hayır; deferred.
3. **DayDetailPanel, FAB'ı gizler mi?** Panel açıkken FAB hâlâ görünebilir; ancak panel yüksekliği FAB üzerinde baskı yaratabilir. Öneri: Panel açıkken FAB kaybolsun (animasyonla). Flutter Engineer onaylasın.
4. **Takvim başlangıç günü:** Pazartesi mi Pazar mı? `weeklyStartDay` settings key'e göre dinamik. WeekDayHeader buna göre sıralanır. Flutter Engineer uygulamasını doğrulasın.
