# SPEC-012: Summary View

**Sprint:** 4
**Related:** US-TransactionsViews (Sprint 4)
**Reference:** SPEC.md Section 9.1.8, Reference screenshot 17
**Parent scaffold:** SPEC-008 (TransactionsScreen)

---

## Purpose

Summary View, seçili ay için finansal bir özet sunar. Üstte toplam gelir, toplam gider, net bakiye ve tasarruf oranı kartlarını gösterir; altında harcama kategorilerine göre Top-5 listeleme yer alır. Aylık bütçe durumu ve hesap bazlı gider dağılımı da bu görünümde özetlenir. Bir bakışta aylık durumu anlamak için tasarlanmıştır.

---

## Layout

```
┌─────────────────────────────────────────────┐
│  [MonthNavigator]                           │  ← SPEC-008
│  [PeriodTabBar — Summary aktif]             │
│  [IncomeSummaryBar]                         │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  STAT KARTI — Top Stats              │   │  ← StatSummaryCard
│  │  ┌──────┐  ┌──────┐  ┌──────┐       │   │
│  │  │ Gelir│  │ Gider│  │ Tasarruf│    │   │
│  │  │ mavi │  │ coral│  │ oranı  │    │   │
│  │  │€ 0,00│  │€651 │  │ -inf%  │    │   │
│  │  └──────┘  └──────┘  └──────┘       │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  HESAPLAR KARTI                      │   │  ← AccountsCard
│  │  [🏦] Accounts                       │   │
│  │  ┌──────────────────────────────┐    │   │
│  │  │ Gider (Cash, Accounts) €651  │    │   │
│  │  └──────────────────────────────┘    │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  BÜTÇE KARTI                         │   │  ← BudgetCard
│  │  [Today▾]                            │   │
│  │  Total Budget     ░░░░░░░░░░   0%    │   │
│  │  € 0,00    0,00              0,00    │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  HARCAMA DAĞILIMI                    │   │  ← CategoryBreakdownCard
│  │  Top 5 Kategori                      │   │
│  │  ████ 🍜 Food         € 198,44  30%  │   │
│  │  ███  🛒 Groceries    € 163,55  25%  │   │
│  │  ██   🚕 Transport    € 120,00  18%  │   │
│  │  ██   🧘 Health       €  85,00  13%  │   │
│  │  █    📚 Education    €  60,00   9%  │   │
│  │  [ Tümünü Gör ]                      │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  📊  Excel'e Aktar                   │   │  ← ExportCard
│  └──────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│  [AdBannerBar — free tier]                  │
└─────────────────────────────────────────────┘

Sağ alt (z-layer):
  ┌──────┐  ← PrimaryFAB (56dp, +)
```

---

## Component Hierarchy

```
SummaryView (ConsumerWidget)
└── SingleChildScrollView
    └── Column
        ├── StatSummaryCard
        ├── SizedBox (height: AppSpacing.md = 12dp)
        ├── AccountsCard
        ├── SizedBox (height: AppSpacing.md)
        ├── BudgetCard
        ├── SizedBox (height: AppSpacing.md)
        ├── CategoryBreakdownCard
        ├── SizedBox (height: AppSpacing.md)
        ├── ExportCard
        └── SizedBox (height: FAB_height + AdBanner_height + AppSpacing.lg)
```

---

## StatSummaryCard Spec

```
┌──────────────────────────────────────────────────────┐
│  ┌─────────────────┐  ┌──────────────────────────┐   │
│  │    Gelir        │  │     Tasarruf Oranı        │   │
│  │   € 0,00        │  │         -inf%             │   │
│  │  (mavi renk)    │  │   (expense coral veya     │   │
│  └─────────────────┘  │    income mavi)           │   │
│  ┌─────────────────┐  └──────────────────────────┘   │
│  │    Gider        │                                   │
│  │   € 651,13      │                                   │
│  │  (coral renk)   │                                   │
│  └─────────────────┘                                  │
└──────────────────────────────────────────────────────┘
```

### Layout: 2 sütun, sol sütunda 2 küçük kart (üst üste), sağ sütunda 1 büyük kart

| Element | Token |
|---------|-------|
| Kart background | `AppColors.bgSecondary` |
| Kart radius | `AppRadius.lg` (16dp) |
| Kart margin | `AppSpacing.lg` (16dp) yatay |
| Kart iç padding | `AppSpacing.lg` (16dp) |
| Sol sütun mini kart background | `AppColors.bgTertiary` |
| Sol sütun mini kart radius | `AppRadius.md` (10dp) |
| Mini kart padding | `AppSpacing.md` (12dp) |
| Mini kart arası boşluk | `AppSpacing.sm` (8dp) |
| Sol/sağ sütun arası boşluk | `AppSpacing.sm` (8dp) |
| **Gelir etiketi** | `AppTypography.caption1`, `AppColors.textSecondary`, "Gelir" / "Income" |
| **Gelir tutarı** | `AppTypography.moneyMedium`, `AppColors.income` |
| **Gider etiketi** | `AppTypography.caption1`, `AppColors.textSecondary`, "Gider" / "Expense" |
| **Gider tutarı** | `AppTypography.moneyMedium`, `AppColors.expense` |
| **Sağ kart — Tasarruf etiketi** | `AppTypography.caption1`, `AppColors.textSecondary`, "Tasarruf Oranı" / "Savings Rate" |
| **Tasarruf değeri** | `AppTypography.title2` (22px w600), ortalanmış |
| Tasarruf oranı pozitif | `AppColors.income` |
| Tasarruf oranı negatif | `AppColors.expense` |
| Tasarruf hesabı | `((income - expense) / income) * 100` → `%` ile; gelir = 0 ise "—" göster |
| Tasarruf formatı | "%24,5" (Türkçe) / "24.5%" (İngilizce) |

---

## AccountsCard Spec

```
┌──────────────────────────────────────────────────────┐
│  [🏦]  Hesaplar                          →           │
│  ┌────────────────────────────────────────────────┐  │
│  │   Gider (Nakit, Hesaplar)            € 651,13  │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Kart background | `AppColors.bgSecondary` |
| Kart radius | `AppRadius.lg` |
| Kart margin | `AppSpacing.lg` yatay |
| Kart padding | `AppSpacing.lg` |
| Başlık satırı yüksekliği | 40dp |
| Başlık ikonu | Phosphor `Wallet`, `AppColors.textSecondary`, 20dp |
| Başlık metni | `AppTypography.headline`, `AppColors.textPrimary` |
| Sağ ok | Phosphor `CaretRight`, `AppColors.textTertiary`, 16dp |
| Tüm başlık satırı tıklanabilir | → AccountsScreen navigate et |
| İçerik hücre background | `AppColors.bgTertiary` |
| İçerik hücre radius | `AppRadius.md` |
| İçerik hücre padding | `AppSpacing.md` dikey, `AppSpacing.lg` yatay |
| Açıklama metni | `AppTypography.subhead`, `AppColors.textSecondary` |
| Tutar | `AppTypography.moneyMedium`, `AppColors.expense` (gider vurgusu) |

### İçerik
- Seçili aydaki toplam gider; hangi hesap tiplerinin dahil olduğu parantez içinde: "(Nakit, Hesaplar)" / "(Cash, Accounts)"
- `includeInTotals = true` olan hesap gruplarından gelen giderler dahil
- Eğer hiç gider yoksa: "Bu ay gider yok." / "No expenses this month." (`AppColors.textTertiary`)

---

## BudgetCard Spec

```
┌──────────────────────────────────────────────────────┐
│  [📊]  Bütçe                    [Bugün ▾]  →        │
│                                                      │
│  Toplam Bütçe            ░░░░░░░░░░░░░░   0%        │
│  € 0,00      0,00                    0,00            │
└──────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Kart background | `AppColors.bgSecondary` |
| Kart radius | `AppRadius.lg` |
| Kart margin | `AppSpacing.lg` yatay |
| Kart padding | `AppSpacing.lg` |
| Başlık ikonu | Phosphor `ChartBar`, `AppColors.textSecondary`, 20dp |
| Başlık metni | `AppTypography.headline`, `AppColors.textPrimary` |
| "Bugün" chip | Küçük pill chip, `AppColors.bgTertiary`, `AppTypography.caption1`, `AppColors.textSecondary`, `AppRadius.pill`, 24dp yüksek |
| Sağ ok | Phosphor `CaretRight`, `AppColors.textTertiary`, 16dp — BudgetScreen'e navigate |
| Tüm başlık satırı tıklanabilir | → BudgetView (Stats sekmesi, Budget sub-tab) |
| Bütçe etiketi | `AppTypography.caption1`, `AppColors.textTertiary` |
| Progress bar | Tam genişlik, 8dp yüksek, `AppRadius.pill` |
| Progress bar arka plan | `AppColors.bgTertiary` |
| Progress bar dolgu (normal) | `AppColors.income` |
| Progress bar dolgu (>80%) | `AppColors.warning` |
| Progress bar dolgu (>100%) | `AppColors.error` |
| "Bugün" göstergesi | Dikey 12dp çizgi, `AppColors.textTertiary`, progress bar üzerinde oran hesaplı konumda |
| Alt satır: Harcanan | `AppTypography.moneySmall`, `AppColors.textSecondary` |
| Alt satır: Bugüne kadar bekl. | `AppTypography.moneySmall`, `AppColors.textTertiary` |
| Alt satır: Bütçe toplam | `AppTypography.moneySmall`, `AppColors.textSecondary` |
| Oran yüzdesi | `AppTypography.moneySmall`, renk progress durumuna göre |

### Bütçe Ayarlanmamışsa
```
┌──────────────────────────────────────────────────────┐
│  [📊]  Bütçe                               →        │
│  Bütçe henüz ayarlanmadı.                            │
│  [ Bütçe Ayarla ]                                    │
└──────────────────────────────────────────────────────┘
```
- CTA: `AppButton` ghost, "Bütçe Ayarla" / "Set Budget", BudgetSettingScreen'e navigate

---

## CategoryBreakdownCard Spec

```
┌──────────────────────────────────────────────────────┐
│  [🗂️]  Harcama Dağılımı — Top 5          →          │
├──────────────────────────────────────────────────────┤
│  ████████  🍜  Food           € 198,44   30,5%       │
│  ██████    🛒  Groceries      € 163,55   25,1%       │
│  ████      🚕  Transport      € 120,00   18,4%       │
│  ███       🧘  Health         €  85,00   13,1%       │
│  ██        📚  Education      €  60,00    9,2%       │
│                                                      │
│                 [ Tümünü Gör ]                       │
└──────────────────────────────────────────────────────┘
```

### Kart Genel

| Element | Token |
|---------|-------|
| Kart background | `AppColors.bgSecondary` |
| Kart radius | `AppRadius.lg` |
| Kart margin | `AppSpacing.lg` yatay |
| Kart padding | `AppSpacing.lg` |
| Başlık ikonu | Phosphor `ChartPie`, `AppColors.textSecondary`, 20dp |
| Başlık metni | `AppTypography.headline`, `AppColors.textPrimary` |
| Sağ ok | Phosphor `CaretRight`, `AppColors.textTertiary` — Stats sekmesine navigate |
| Başlık satırı tıklanabilir | → StatsScreen (Exp. sub-tab) |

### CategoryBreakdownRow Spec

```
[ProgressBar]  [Emoji]  [Kategori adı]   [Tutar]  [Oran%]
    8dp h       20dp       bodyMedium    moneySmall  caption1
```

| Element | Token |
|---------|-------|
| Satır yüksekliği | 48dp |
| Sol padding | 0 (kart paddingleri geçerli) |
| Progress bar | Satırın solunda, dikey yönde değil, arka planda yatay renk bandı |
| Progress bar arka planı | `AppColors.bgTertiary` tam satır genişliği, `AppRadius.sm` |
| Progress bar dolgu | Kategoriye atanan renk (Stats pie chart ile aynı renk paleti), yüzdeye göre genişlik |
| Progress bar yüksekliği | 36dp (satır yüksekliğinden 6dp margin), radius `AppRadius.sm` |
| Emoji | 20x20dp, progress bar üzerinde z-layer (overlay), sol 12dp indent |
| Kategori adı | `AppTypography.bodyMedium`, `AppColors.textPrimary`, progress bar üzerinde |
| Tutar | `AppTypography.moneySmall`, `AppColors.textPrimary`, sağ hizalı |
| Oran | `AppTypography.caption1`, `AppColors.textSecondary`, tutar sağında 8dp boşluk |
| Satır arası divider | Yok |
| Satır tap | → StatsScreen o kategoriye scroll |

### Renk Paleti (Kategori Renkleri)

Stats pie chart ile aynı sıra, sabit 5 renk top-5 için:
1. `#FF6B5C` (brandPrimary / coral)
2. `#4A90E2` (income / mavi)
3. `#FFA726` (warning / turuncu)
4. `#4CAF50` (success / yeşil)
5. `#AB47BC` (mor — yeni token: `AppColors.categoryPurple`)

> Not: Flutter Engineer'a: `AppColors.categoryPurple = Color(0xFFAB47BC)` token'ı eklenmelidir.

### "Tümünü Gör" Butonu

| Element | Token |
|---------|-------|
| Stil | `AppButton` ghost, "Tümünü Gör" / "See All" |
| Hizalama | Merkez |
| Tap | → StatsScreen (Stats tab, Exp. görünümü) |
| Görünürlük | Her zaman görünür (kategorisi 1 olsa bile) |

---

## ExportCard Spec

```
┌──────────────────────────────────────────────────────┐
│  [📊]  Excel'e Aktar                        →        │
└──────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Kart background | `AppColors.bgSecondary` |
| Kart radius | `AppRadius.lg` |
| Kart margin | `AppSpacing.lg` yatay |
| Kart yüksekliği | 52dp |
| Kart padding | `AppSpacing.lg` yatay, ortalanmış |
| İkon | Phosphor `FileXls`, `AppColors.brandPrimary`, 20dp |
| Metin | `AppTypography.bodyMedium`, `AppColors.textPrimary`, "Excel'e Aktar" / "Export to Excel" |
| Sağ ok | Phosphor `CaretRight`, `AppColors.textTertiary` |
| Tap | → BackupScreen (More sekmesi) veya doğrudan export flow başlatır (PM kararı) |

---

## States

### Default
- Tüm kartlar görünür
- Seçili ay: cari ay

### Loading
- Her kart için shimmer: kart boyu, satır yüksekliği kadar shimmer bloklar
- CategoryBreakdownCard: 5 adet 48dp shimmer satır
- BudgetCard: progress bar yerine shimmer çizgi

### Populated
- Normal görünüm

### Empty (Ayda hiç işlem yok)

#### StatSummaryCard
- Gelir: € 0,00 (mavi), Gider: € 0,00 (coral), Tasarruf: "—" (dash)

#### AccountsCard
- "Bu ay gider yok." mesajı

#### BudgetCard
- Bütçe ayarlandıysa: %0 progress, 0,00 harcama
- Bütçe ayarlanmadıysa: "Bütçe henüz ayarlanmadı" CTA

#### CategoryBreakdownCard
```
┌──────────────────────────────────────────────────────┐
│  [📈]  Harcama Dağılımı — Top 5                      │
│                                                      │
│          Bu ay henüz harcama yok.                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```
- Mesaj: `AppTypography.subhead`, `AppColors.textSecondary`, ortalanmış
- "Tümünü Gör" butonu gizlenir
- Yükseklik: 80dp (başlık + mesaj)

### Error
- Her kart kendi içinde hata gösterir: küçük satır "Yüklenemedi. [Tekrar Dene]"
- Tam sayfa `EmptyStateView` gösterilmez (diğer kartlar çalışıyor olabilir)

---

## Interactions

| Tetikleyici | Aksiyon |
|-------------|---------|
| AccountsCard başlık tap | AccountsScreen'e navigate |
| BudgetCard başlık tap | Stats sekmesi Budget sub-tab'a navigate |
| Bütçe ayarla CTA | BudgetSettingScreen (More > Budget Setting)'e navigate |
| CategoryBreakdownRow tap | Stats sekmesi Exp. view, o kategoriye scroll |
| "Tümünü Gör" tap | Stats sekmesi Exp. view'a navigate |
| ExportCard tap | BackupScreen veya export dialog |
| FAB tap | AddTransactionModal |
| MonthNavigator | SPEC-008 davranışı; ay değişince tüm kartlar yenilenir |

---

## Accessibility

| Element | Semantics Label |
|---------|----------------|
| StatSummaryCard | "Özet. Gelir: € 0,00, Gider: € 651,13, Tasarruf oranı: -infinity yüzde." |
| AccountsCard | "Hesaplar kartı. Naisan toplam gider: € 651,13. Hesaplara gitmek için dokunun." |
| BudgetCard | "Bütçe kartı. Toplam bütçe: Ayarlanmamış. Bütçe ayarlamak için dokunun." |
| CategoryBreakdownRow | "1. [Kategori adı]. Tutar: € 198,44. Yüzde: yüzde 30,5." |
| "Tümünü Gör" | "Tüm harcama kategorilerini gör. İstatistikler ekranına gider." |
| ExportCard | "Excel'e aktar." |
| Progress bar (BudgetCard) | "Bütçe kullanımı: yüzde 42. Aylık bütçe: € 1.500,00." |
| CategoryBreakdownRow progress | Her satır için `Semantics.hint` yok; semantics label yeterli |

- Tüm kartlar `Semantics(container: true)` ile gruplandırılmış
- Focus sırası: StatSummaryCard → AccountsCard → BudgetCard → CategoryBreakdownCard (satır satır) → ExportCard → FAB
- Tasarruf oranı infinity değerinde: "Hesaplanamadı" / "Not available" söylenir (gelir 0 iken)

---

## Edge Cases

| Durum | Davranış |
|-------|---------|
| Gelir = 0, gider > 0 | Tasarruf oranı: "—" (dash); sonsuz veya negatif infinity gösterilmez |
| Gelir > 0, gider = 0 | Tasarruf oranı: "% 100" |
| Gelir = gider | Tasarruf oranı: "% 0" |
| Hiç bütçe ayarlanmamış | BudgetCard CTA versiyonu gösterilir |
| Sadece 2 kategori harcaması var | Top 5 yerine 2 satır; 3 boş satır shimmer değil, boş gösterilir |
| Kategori adı çok uzun | `maxLines: 1`, ellipsis |
| Çok büyük tutar | "€ 1,2M" kısaltması |
| CategoryBreakdownCard için renk paleti 5'ten az kategori | Renk paleti 1-5 sıraya göre atanır; boş satır renk atamaz |
| Seçili ay gelecek ay | Tüm değerler 0,00 / boş; empty state mesajları gösterilir |
| Aynı tutarda birden fazla kategori | İlk 5'e girenler sıra kararlı (alfabetik ikincil sıralama) |

---

## New Components (Bu spec ile tanımlananlar)

| Component | File | Notes |
|-----------|------|-------|
| `StatSummaryCard` | `features/transactions/presentation/widgets/stat_summary_card.dart` | `income`, `expense`, `savingsRate`, `currency`. |
| `AccountsSummaryCardWidget` | `features/transactions/presentation/widgets/accounts_summary_card_widget.dart` | `totalExpense`, `accountGroupNames`, `onTap`. (Not: `AccountsSummaryBar` farklı bileşen — SPEC-004.) |
| `BudgetSummaryCard` | `features/transactions/presentation/widgets/budget_summary_card.dart` | `totalBudget`, `spent`, `expectedSpend`, `progressRatio`, `isSetUp`, `onTap`, `onSetBudgetTap`. |
| `CategoryBreakdownCard` | `features/transactions/presentation/widgets/category_breakdown_card.dart` | `categories` (List<CategorySummary> max 5), `onCategoryTap`, `onSeeAllTap`. |
| `CategoryBreakdownRow` | `features/transactions/presentation/widgets/category_breakdown_row.dart` | `rank`, `emoji`, `name`, `amount`, `percentage`, `color`, `onTap`. Progress bar overlay. |
| `ExportActionCard` | `features/transactions/presentation/widgets/export_action_card.dart` | `onTap`. Basit tap kart. |

---

## Open Questions

1. **ExportCard tap akışı:** Doğrudan BackupScreen'e mi navigate, yoksa "Şu anki ay / Tüm veriler" seçimi yapan küçük bir bottom sheet mi gösterilsin? Öneri: bottom sheet ile seçenek — PM kararı.
2. **CategoryBreakdownCard renk paleti:** Beşinci renk `AppColors.categoryPurple` yeni token gerektiriyor. Flutter Engineer bu token'ı `app_colors.dart`'a eklemeli. UX Designer onayı: `Color(0xFFAB47BC)`.
3. **AccountsCard içeriği:** Sadece toplam gider mi gösterilmeli, yoksa hem gider hem gelir mi? Referans ekran 17'ye göre sadece gider. Onay: Sadece gider.
4. **Summary View'da Income görünümü:** IncomeSummaryBar'da Income tıklanınca Summary View income breakdown'unu mu göstermeli? Bu spec'te: CategoryBreakdownCard daima expense gösterir; income breakdown için Stats ekranına yönlendir.
5. **BudgetCard "Bugün" chip'i:** "Bugün" chip'i sadece bilgi amaçlı mı, yoksa tıklanınca bir aksiyon var mı? Bu spec: yalnızca görsel gösterge, tap aksiyonu yok.
