# MONEY MANAGER KLONU — TEKNİK SPESİFİKASYON DOKÜMANI (SPEC.md)

> **Versiyon:** 1.0
> **Hazırlanma Tarihi:** 28 Nisan 2026
> **Hedef:** Money Manager (Realbyte) uygulamasının Flutter ile cross-platform (iOS + Android) klonu
> **Kullanım:** Bu doküman Claude Code agent'ları (flutter-engineer, product-manager, code-reviewer, devops-engineer) tarafından okunup uygulanmak üzere yazılmıştır.

---

## 0. AGENT'LARA TALİMATLAR (NASIL OKUNUR)

Her agent bu dokümanı okurken kendi sorumluluk alanına odaklanmalıdır:

- **product-manager:** Bölüm 1, 2, 3, 4 (özellik kapsamı, kullanıcı akışları, MVP scope)
- **flutter-engineer:** Bölüm 5, 6, 7, 8, 9, 10 (mimari, UI, state, veri katmanı, ekran specleri)
- **code-reviewer:** Bölüm 11, 14 (test kapsamı, kalite kriterleri, kabul kriterleri)
- **devops-engineer:** Bölüm 12, 13 (CI/CD, dağıtım, çevre yönetimi)

Her ekran için **EXACT layout spesifikasyonu** verilmiştir (Bölüm 9). UI'ı pikselbazında değil, **referans ekran görüntülerine ve verilen ölçü/davranışa sadık** kalarak inşa edin.

---

## 1. ÜRÜN ÖZETİ

### 1.1. Vizyon
Realbyte Money Manager'ın çift kayıtlı muhasebe (double-entry bookkeeping) yaklaşımını koruyan, ancak modern UX, gerçek zamanlı bulut senkronizasyonu, banka entegrasyonu opsiyonu ve Türkçe lokalizasyonla farklılaşan bir kişisel finans uygulaması. Adı (kod adı): **MoneyWise** (final marka adı sonra belirlenecek).

### 1.2. Hedef Kitle
- Birincil: 22-45 yaş arası, kişisel/aile bütçesi tutmak isteyen, mobil-first kullanıcılar
- İkincil: Küçük işletme sahipleri, freelance çalışanlar (basit nakit akışı takibi için)
- Coğrafi: Önce Türkiye, sonra global (TR, EN, DE, ES dilleri Faz 1)

### 1.3. Temel Önerme
- Hızlı işlem girişi (3 dokunuş içinde tamamlanır)
- Çift kayıt sistemi → her zaman doğru hesap bakiyesi
- Kategori bazlı bütçe + carry-over
- Çoklu para birimi
- Yedekleme her zaman ücretsiz, sync premium

### 1.4. Olmayacak Şeyler (Out of Scope, Faz 1)
- Banka API entegrasyonu (Faz 3)
- AI kategori önerisi (Faz 4)
- Yatırım portföy takibi (Faz 4)
- Aile/grup paylaşımı (Faz 3)

---

## 2. TASARIM SİSTEMİ (DESIGN SYSTEM)

Referans uygulamanın UI'ı çok minimal ve fonksiyonel. Bu DS'yi takip edin.

### 2.1. Renk Paleti

#### Dark Mode (varsayılan, ekran görüntülerine sadık)
```dart
// Primary Brand (Coral/Salmon Red)
const Color brandPrimary = Color(0xFFFF6B5C);     // Ana vurgu - butonlar, aktif tab, save buton
const Color brandPrimaryDim = Color(0xFFE85A4D);  // Hover/pressed state
const Color brandPrimaryGlow = Color(0x33FF6B5C); // Border/shadow vurguları

// Backgrounds
const Color bgPrimary = Color(0xFF1A1B1E);     // Ana arka plan (en koyu)
const Color bgSecondary = Color(0xFF24252A);   // Kart, input, bottom-sheet
const Color bgTertiary = Color(0xFF2E2F35);    // Hover, divider üstü, seçili satır

// Text
const Color textPrimary = Color(0xFFFFFFFF);   // Ana metin
const Color textSecondary = Color(0xFFB0B3B8); // İkincil/açıklama
const Color textTertiary = Color(0xFF6B6E76);  // Disabled, placeholder
const Color textOnBrand = Color(0xFFFFFFFF);   // Brand renkler üstündeki yazı

// Semantik (gelir/gider)
const Color income = Color(0xFF4A90E2);  // Mavi - Gelir
const Color expense = Color(0xFFFF6B5C); // Kırmızı/coral - Gider (brand ile aynı)
const Color neutral = Color(0xFFFFFFFF); // Beyaz - Total/Bakiye

// Sistem
const Color divider = Color(0xFF2E2F35);
const Color border = Color(0xFF3A3B42);
const Color success = Color(0xFF4CAF50);
const Color warning = Color(0xFFFFA726);
const Color error = Color(0xFFE53935);
```

#### Light Mode
```dart
const Color bgPrimaryLight = Color(0xFFFFFFFF);
const Color bgSecondaryLight = Color(0xFFF5F5F7);
const Color bgTertiaryLight = Color(0xFFEAEAEC);
const Color textPrimaryLight = Color(0xFF1A1B1E);
const Color textSecondaryLight = Color(0xFF6B6E76);
// Brand renkleri aynı kalır
```

### 2.2. Tipografi

```dart
// Font ailesi: SF Pro Display (iOS), Roboto (Android), Inter (fallback)
class AppTypography {
  static const TextStyle largeTitle = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const TextStyle title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const TextStyle title2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
  static const TextStyle title3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
  static const TextStyle bodyMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle callout = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle subhead = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const TextStyle footnote = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const TextStyle caption1 = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle caption2 = TextStyle(fontSize: 11, fontWeight: FontWeight.w400);

  // Para birimi gösterimi - büyük ve kalın
  static const TextStyle moneyLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]);
  static const TextStyle moneyMedium = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]);
  static const TextStyle moneySmall = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]);
}
```

### 2.3. Spacing & Sizing
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;   // Ana button radius (Save buton ekran 1)
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;
}

class AppHeights {
  static const double inputField = 48.0;
  static const double button = 52.0;
  static const double tabBar = 49.0;       // Bottom tab (iOS standart)
  static const double appBar = 44.0;       // Top app bar
  static const double listItem = 56.0;
  static const double bannerAd = 50.0;
}
```

### 2.4. İkonografi
- **Sistem ikonları:** Phosphor Icons (`phosphor_flutter` paketi) — modern, line-style
- **Kategori ikonları:** Native Emoji (🍜, 👫, 🐶, 🚕, 🖼️, 🪑, 🧥, 💄, 🧘, 📚, 🎁, 🤵, 🏠, 🚬) — referans uygulama ile birebir aynı
- **Brand logo:** Kendi tasarımınız (cüzdan + kalem kombinasyonu önerilir)

### 2.5. Kompozisyon Kuralları
- Her form alanı solunda label (gri), sağında değer (beyaz/coral) → Bkz. Ekran 1 (Expense ekleme)
- Liste satırları: 56px yüksek, sol-orta-sağ sütun düzeni
- Ana CTA butonu: 52px yüksek, brand renk dolgu, beyaz yazı, 10px radius
- İkincil buton: aynı boyut, brand renk border, brand renk yazı
- Tab bar (alt): 4 ikon + label, aktif olan brand renk

---

## 3. UYGULAMA NAVİGASYONU

### 3.1. Bottom Tab Navigator (4 sekme)
Tüm ekranlarda alt kısımda sabit:

| # | İkon | Label | Route | Açıklama |
|---|---|---|---|---|
| 1 | Defter (📒) | "**28.4.**" (bugünün gün.ay) | `/transactions` | İşlem listesi (Trans.) |
| 2 | Çubuk grafik | "Stats" | `/stats` | İstatistikler |
| 3 | Yığılmış paralar | "Accounts" | `/accounts` | Hesaplar |
| 4 | 3 nokta | "More" | `/more` | Ayarlar ve diğer |

> **Önemli:** Tab 1'in label'ı dinamiktir — bugünün tarihi (gün.ay formatında) gösterilir.

### 3.2. Sayfa Yığını
Her tab kendi navigator stack'ine sahiptir (iOS standardı). Modal sayfalar (transaction ekleme gibi) tüm tab'ları kaplar.

```
RootApp (MaterialApp)
└── BottomTabScaffold
    ├── Tab1: TransactionsNavigator
    │   ├── TransactionsScreen (5 alt-tab: Daily/Calendar/Monthly/Summary/Description)
    │   ├── TransactionDetailScreen
    │   └── ... (filter, search vb.)
    ├── Tab2: StatsNavigator
    │   └── StatsScreen (3 alt-tab: Stats/Budget/Note + Income/Exp)
    ├── Tab3: AccountsNavigator
    │   ├── AccountsScreen
    │   ├── AccountDetailScreen
    │   └── AccountAddEditScreen
    └── Tab4: MoreNavigator
        ├── MoreScreen (Settings ana)
        ├── BackupScreen
        ├── PasscodeScreen
        ├── BudgetSettingScreen
        ├── CategoryManagementScreen (Income/Expense)
        ├── AccountSettingsScreen
        ├── TransactionSettingsScreen
        ├── RepeatSettingsScreen
        ├── StyleScreen (theme)
        ├── LanguageScreen
        ├── CurrencyScreen (main + sub)
        ├── AlarmScreen
        ├── HelpScreen
        ├── FeedbackScreen
        └── PremiumScreen (Remove Ads)

Modal Sheets:
├── AddTransactionModal (Income/Expense/Transfer)
├── BookmarkPickerModal
├── CategoryPickerModal
├── AccountPickerModal
└── DatePickerModal
```

### 3.3. Modal Sayfa Davranışları
- **Add Transaction (`+` butonu):** Bottom-sheet (iOS), tam ekran modal (Android), slide-up animasyon, dismiss = swipe down veya back butonu
- **Picker'lar:** Cupertino-style action sheet altta, dismiss = tap-outside veya Cancel butonu

# SPEC — BÖLÜM 2: MİMARİ VE VERİ KATMANI

## 4. TEKNOLOJİ YIĞINI

### 4.1. Mobil İstemci
| Katman | Seçim | Versiyon (min) | Sebep |
|---|---|---|---|
| Framework | Flutter | 3.22+ | Tek kod tabanı (iOS+Android) |
| Dil | Dart | 3.4+ | Null-safety, records |
| State Management | **Riverpod** (`flutter_riverpod`) | 2.5+ | Code-gen, derleme zamanı güvenliği, test edilebilir |
| Navigasyon | **go_router** | 14+ | Declarative, deep-link friendly |
| Lokal DB | **Drift** (SQLite üzerinde) | 2.18+ | Type-safe queries, code-gen, reactive streams |
| Lokal şifreleme | `sqlcipher_flutter_libs` + Drift | latest | Hassas finans verisi şifrelenmeli |
| Network | **dio** | 5.4+ | Interceptor, retry, log |
| API model gen | `freezed` + `json_serializable` | latest | Immutable models, sealed unions |
| Date/Time | `intl`, `timezone` | latest | i18n date format |
| Para birimi | `money2` | latest | Decimal-precise hesaplama |
| Charts | `fl_chart` | 0.68+ | Pie, bar, line — performanslı |
| Auth | `firebase_auth` veya `supabase_auth` | latest | Email + Apple/Google sign-in |
| Cloud sync | `supabase_flutter` (önerilen) | latest | Postgres + realtime, açık kaynak |
| Cloud Storage | `firebase_storage` veya `supabase_storage` | - | Fiş fotoğrafları |
| Push | `firebase_messaging` | latest | Bildirimler (sonra) |
| Lokal bildirim | `flutter_local_notifications` | latest | Alarm/hatırlatıcı |
| Biyometrik | `local_auth` | latest | FaceID, TouchID, parmak izi |
| Excel import/export | `excel`, `csv` | latest | Bulk veri yedek/geri yükleme |
| File picker | `file_picker` | latest | Kullanıcı dosya seçimi |
| Image picker | `image_picker` | latest | Fiş fotoğrafı |
| In-app purchase | `in_app_purchase` | latest | Premium IAP |
| Reklam (free tier) | `google_mobile_ads` | latest | Banner reklam (alt kısım) |
| Crash | `firebase_crashlytics` veya `sentry_flutter` | latest | Hata takibi |
| Analytics | `firebase_analytics` veya `mixpanel_flutter` | latest | Ürün metrikleri |

### 4.2. Backend (Cloud Sync — Faz 2 itibariyle)
| Katman | Seçim | Sebep |
|---|---|---|
| BaaS | **Supabase** (önerilen) veya Firebase | Açık kaynak, PostgreSQL, RLS ile güvenli |
| DB | PostgreSQL (Supabase ile dahil) | İlişkisel veri, RLS, JSON desteği |
| Auth | Supabase Auth | Email, OAuth (Apple/Google), magic link |
| Storage | Supabase Storage | Fiş fotoğrafı (S3 uyumlu) |
| Realtime | Supabase Realtime | Cihazlar arası canlı sync |
| Edge Functions | Supabase Edge (Deno) | FX rate fetch, push trigger |

### 4.3. Geliştirme Araçları
- IDE: VS Code veya Android Studio
- Versiyon kontrol: Git + GitHub (private repo)
- CI/CD: GitHub Actions (test, build, distribute)
- Beta dağıtım: TestFlight (iOS), Firebase App Distribution (Android internal)

---

## 5. MİMARİ KATMANLAR

Clean Architecture + Feature-First klasör yapısı kullanın.

```
lib/
├── main.dart                       # Entry point, env setup
├── app.dart                        # MaterialApp + router
├── bootstrap.dart                  # DI, Hive/Drift init
│
├── core/                           # Tüm feature'ların paylaştığı altyapı
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_strings.dart        # Hard-coded keys (i18n için)
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData light + dark
│   │   └── theme_extensions.dart   # Custom theme props
│   ├── extensions/
│   │   ├── date_extensions.dart
│   │   ├── num_extensions.dart     # toMoney(), toFormatted()
│   │   └── context_extensions.dart # context.colors, context.text
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_helpers.dart
│   │   └── validators.dart
│   ├── widgets/                    # Paylaşılan widgetlar
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_bottom_sheet.dart
│   │   ├── currency_text.dart      # Tabular fig, +/- renkli
│   │   ├── month_year_picker.dart
│   │   └── loading_indicator.dart
│   ├── router/
│   │   ├── app_router.dart         # go_router config
│   │   └── routes.dart             # Route name constants
│   ├── i18n/
│   │   ├── arb/
│   │   │   ├── app_tr.arb
│   │   │   ├── app_en.arb
│   │   │   ├── app_de.arb
│   │   │   └── app_es.arb
│   │   └── locale_provider.dart
│   └── error/
│       ├── failures.dart           # Sealed Failure types
│       └── error_handler.dart
│
├── data/                           # Veri katmanı (lokal + uzak)
│   ├── local/
│   │   ├── database.dart           # Drift database
│   │   ├── tables/
│   │   │   ├── accounts_table.dart
│   │   │   ├── account_groups_table.dart
│   │   │   ├── categories_table.dart
│   │   │   ├── transactions_table.dart
│   │   │   ├── budgets_table.dart
│   │   │   ├── bookmarks_table.dart
│   │   │   ├── recurring_table.dart
│   │   │   ├── memos_table.dart
│   │   │   ├── settings_table.dart  # KV store
│   │   │   └── currencies_table.dart
│   │   └── daos/                   # Data Access Objects
│   │       ├── account_dao.dart
│   │       ├── category_dao.dart
│   │       ├── transaction_dao.dart
│   │       ├── budget_dao.dart
│   │       └── ...
│   ├── remote/                     # Sync adapter (Faz 2+)
│   │   ├── supabase_client.dart
│   │   ├── sync_service.dart
│   │   └── dtos/                   # Network model
│   └── repositories/
│       ├── account_repository.dart
│       ├── transaction_repository.dart
│       ├── budget_repository.dart
│       ├── category_repository.dart
│       └── settings_repository.dart
│
├── domain/                         # İş mantığı, framework-agnostic
│   ├── entities/                   # Pure Dart business objects
│   │   ├── account.dart
│   │   ├── category.dart
│   │   ├── transaction.dart
│   │   ├── budget.dart
│   │   ├── money.dart              # Wrapper, decimal-aware
│   │   └── ...
│   ├── enums/
│   │   ├── transaction_type.dart   # income | expense | transfer
│   │   ├── account_type.dart
│   │   ├── period.dart             # weekly | monthly | annually
│   │   └── ...
│   └── usecases/                   # Tek görevli iş mantığı
│       ├── add_transaction.dart
│       ├── transfer_between_accounts.dart
│       ├── apply_recurring_transactions.dart
│       ├── calculate_account_balance.dart
│       ├── carry_over_budget.dart
│       └── ...
│
├── features/                       # UI + ViewModel feature bazlı
│   ├── transactions/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── transactions_screen.dart       # Trans. tab ana
│   │   │   │   ├── daily_view.dart
│   │   │   │   ├── calendar_view.dart
│   │   │   │   ├── monthly_view.dart
│   │   │   │   ├── summary_view.dart
│   │   │   │   ├── description_view.dart
│   │   │   │   └── add_transaction_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── transaction_list_item.dart
│   │   │   │   ├── month_navigator.dart
│   │   │   │   ├── period_tabs.dart
│   │   │   │   └── ...
│   │   │   └── providers/
│   │   │       ├── transactions_provider.dart      # Riverpod
│   │   │       ├── add_transaction_provider.dart
│   │   │       └── ...
│   │   └── transactions.dart       # Public barrel
│   ├── stats/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── stats_screen.dart
│   │   │   │   ├── budget_view.dart
│   │   │   │   └── note_view.dart
│   │   │   ├── widgets/
│   │   │   │   ├── pie_chart_widget.dart
│   │   │   │   ├── budget_bar.dart
│   │   │   │   └── category_legend.dart
│   │   │   └── providers/
│   │   └── stats.dart
│   ├── accounts/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── accounts_screen.dart
│   │   │   │   └── account_add_edit_screen.dart
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── accounts.dart
│   ├── more/                       # Settings & misc
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── more_screen.dart
│   │   │   │   ├── backup_screen.dart
│   │   │   │   ├── passcode_screen.dart
│   │   │   │   ├── budget_setting_screen.dart
│   │   │   │   ├── category_management_screen.dart
│   │   │   │   ├── transaction_settings_screen.dart
│   │   │   │   ├── repeat_settings_screen.dart
│   │   │   │   ├── style_screen.dart
│   │   │   │   ├── language_screen.dart
│   │   │   │   ├── currency_screen.dart
│   │   │   │   └── premium_screen.dart
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── more.dart
│   └── auth/                       # Faz 2+
│       └── ...
│
└── services/                       # Cross-cutting services
    ├── biometric_service.dart
    ├── notification_service.dart
    ├── ad_service.dart
    ├── analytics_service.dart
    ├── iap_service.dart
    ├── backup_service.dart
    ├── currency_rate_service.dart
    └── recurring_scheduler_service.dart
```

---

## 6. VERİ MODELİ (DRIFT TABLOLARI)

Aşağıdaki tablolar Drift `@DriftDatabase` içine eklenecektir. Her ID UUID v4 (string).

### 6.1. accountGroups

```dart
class AccountGroups extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // AccountGroupType enum: cash | accounts | card | debitCard | savings | topUpPrepaid | investments | overdrafts | loan | insurance | others
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get iconKey => text().nullable()(); // Optional icon ref
  BoolColumn get includeInTotals => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))(); // Soft delete

  @override
  Set<Column> get primaryKey => {id};
}
```

**Varsayılan Account Group'lar (referans Ekran 12):** Cash, Accounts, Card, Debit Card, Savings, Top-Up/Prepaid, Investments, Overdrafts, Loan, Insurance, Others

### 6.2. accounts

```dart
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(AccountGroups, #id)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)(); // ISO 4217: EUR, TRY, USD
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  // currentBalance hesaplanır (CTE veya trigger ile), saklanmaz
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get includeInTotals => boolean().withDefault(const Constant(true))();
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  // Kart için ekstra alanlar
  IntColumn get statementDay => integer().nullable()(); // Hesap kesim günü (1-31)
  IntColumn get paymentDueDay => integer().nullable()(); // Son ödeme günü (1-31)
  RealColumn get creditLimit => real().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 6.3. categories

```dart
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get parentId => text().nullable().references(Categories, #id)(); // null = ana kategori
  TextColumn get iconEmoji => text().nullable()(); // Native emoji
  TextColumn get colorHex => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))(); // Built-in
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Varsayılan Income kategorileri (Ekran 7):** 🤑 Allowance, 💰 Salary, 💵 Petty cash, 🥇 Bonus, Other, 💸 Dividend, 💸 Interest

**Varsayılan Expense kategorileri (Ekran 6):** 🍜 Food, 👫 Social Life, 🐶 Pets, 🚕 Transport, 🖼️ Culture, 🪑 Household, 🧥 Apparel, 💄 Beauty, 🧘 Health, 📚 Education, 🎁 Gift, Other, 🤵 Insurance, 🏠 Rent, 🚬 Cigarette, ve ekran 15'te görülen ek olanlar: Groceries, Restaurant, Parking, Bills, Gym, Medicine

### 6.4. transactions

```dart
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'income' | 'expense' | 'transfer'
  DateTimeColumn get date => dateTime()(); // Tarih + saat
  RealColumn get amount => real()(); // Pozitif değer
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))(); // Ana para birimine göre
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)(); // Sadece transfer için
  TextColumn get categoryId => text().nullable().references(Categories, #id)(); // Transfer için null
  TextColumn get subcategoryId => text().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()(); // Note label (Ekran 1)
  TextColumn get note => text().nullable()();        // Description label (Ekran 1)
  TextColumn get photoUris => text().nullable()();   // JSON array
  TextColumn get recurringId => text().nullable().references(RecurringTransactions, #id)(); // Türetilen tekrar
  TextColumn get bookmarkId => text().nullable()();  // Kaynak bookmark referansı
  BoolColumn get isExcluded => boolean().withDefault(const Constant(false))(); // Toplamlardan hariç
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

**İndeksler:**
- `(date DESC)` — listeleme/takvim sorguları için
- `(accountId, date DESC)` — hesap detayı
- `(categoryId, date DESC)` — kategori bazlı stat
- `(type, date DESC)` — gelir/gider filtreleri

### 6.5. budgets

```dart
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)(); // null = TOTAL bütçe
  RealColumn get amount => real()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get period => text()(); // 'weekly' | 'monthly' | 'annually'
  DateTimeColumn get effectiveFrom => dateTime()(); // Hangi ay/dönemden itibaren
  DateTimeColumn get effectiveTo => dateTime().nullable()(); // null = hala aktif (sonsuz)
  BoolColumn get carryOverEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

> **Davranış:** Bir kategori için bütçe ayarlandığında, sonraki tüm aylar için varsayılandır. Ay-bazlı override için `effectiveFrom` farklı bir aya ayarlanır ve önceki kayıt `effectiveTo` ile kapatılır.

### 6.6. bookmarks

```dart
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income | expense | transfer
  RealColumn get amount => real().nullable()(); // Tutar opsiyonel
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get subcategoryId => text().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get useCount => integer().withDefault(const Constant(0))(); // Kullanım sıklığı
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 6.7. recurringTransactions

```dart
class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // income | expense | transfer
  RealColumn get amount => real()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get frequency => text()(); // daily | weekly | monthly | yearly | custom
  IntColumn get interval => integer().withDefault(const Constant(1))(); // Her N {frequency}
  IntColumn get dayOfMonth => integer().nullable()(); // Aylık için: ayın hangi günü
  TextColumn get dayOfWeek => text().nullable()(); // Haftalık için: 'mon,tue,...'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get installmentCount => integer().nullable()(); // Toplam taksit sayısı
  IntColumn get installmentDone => integer().withDefault(const Constant(0))();
  TextColumn get reflectionTiming => text().withDefault(const Constant('on_the_date'))(); // 'on_the_date' | 'one_day_before' | 'on_app_open'
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 6.8. memos (Daily Notes)

```dart
class Memos extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Yıl-ay-gün (saat 00:00)
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 6.9. settings (KV Store)

```dart
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON-encoded
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
```

**Saklanan keyler (Ekran 9, 10, 11):**
- `language` → 'en', 'tr', 'de', ...
- `theme` → 'system' | 'light' | 'dark'
- `mainCurrency` → 'EUR' | 'TRY' | ...
- `subCurrencies` → JSON array
- `monthlyStartDate` → 1-31
- `weeklyStartDay` → 'monday' ... 'sunday'
- `carryOverEnabled` → bool
- `periodSetting` → 'monthly'
- `incomeExpenseColor` → 'exp' | 'income' (vurgu rengi seçimi)
- `autocomplete` → bool
- `timeInput` → 'none_desc' | 'with_time'
- `startScreen` → 'daily' | 'calendar'
- `swipeAction` → 'change_date' | 'change_period'
- `showDescription` → bool
- `inputOrder` → 'from_amount' | 'from_category'
- `noteButton` → bool
- `passcodeEnabled` → bool
- `passcodeHash` → string (Argon2 hashed)
- `biometricsEnabled` → bool
- `passcodePromptFrequency` → 'always' | 'after_5min' | 'after_30min'
- `cardExpensesDisplayConfig` → 'at_the_time' | 'on_payment_date'
- `transferExpenseSetting` → bool
- `lastBackupAt` → ISO date
- `googleDriveBackup` → bool
- `googleDriveFrequency` → 'daily' | 'weekly' | 'manual'
- `iCloudBackup` → bool
- `premiumStatus` → 'free' | 'premium' | 'syncSubscriber'
- `appLaunchCount` → int
- `lastReviewPromptAt` → ISO date

### 6.10. currencies (Para Birimi Cache)

```dart
class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  IntColumn get decimalDigits => integer().withDefault(const Constant(2))();
  RealColumn get rateToBase => real().withDefault(const Constant(1.0))(); // Main currency'ye oran
  DateTimeColumn get rateUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}
```

### 6.11. syncMetadata (Faz 2+)

```dart
class SyncMetadata extends Table {
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'insert' | 'update' | 'delete'
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {tableName, recordId, operation};
}
```

### 6.12. attachments (Fiş fotoğrafları)

```dart
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get localPath => text().nullable()();   // /documents/attachments/...
  TextColumn get remoteUrl => text().nullable()();   // Supabase storage URL
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 7. ÇİFT KAYITLI MUHASEBE MANTIK (DOUBLE-ENTRY) — KRİTİK

Money Manager'ın temeli. Şu kuralları **mutlaka** uygulayın:

### 7.1. Bakiye Hesaplama
Hesap bakiyesi `accounts.currentBalance` olarak SAKLANMAZ. Her zaman dinamik olarak hesaplanır:

```sql
-- Drift'te (basitleştirilmiş):
account.balance =
  account.initialBalance
  + SUM(transactions WHERE accountId = X AND type = 'income')
  - SUM(transactions WHERE accountId = X AND type = 'expense')
  - SUM(transactions WHERE accountId = X AND type = 'transfer')        -- bu hesap KAYNAK
  + SUM(transactions WHERE toAccountId = X AND type = 'transfer')      -- bu hesap HEDEF
```

Performans için: Reactive computed-stream + Drift trigger ile cache'leme (`account_balance_cache` view).

### 7.2. Transfer Atomik
Bir Transfer işlemi TEK transaction kaydıdır (`type='transfer'`, `accountId=from`, `toAccountId=to`). İki ayrı kayıt OLUŞTURULMAZ. Bakiye hesabı yukarıdaki formülle yapılır.

### 7.3. Asset / Liability Ayrımı (Ekran 13)
- **Assets (Varlıklar):** Cash, Accounts, Debit Card, Savings, Top-Up/Prepaid, Investments → balance > 0 normal
- **Liabilities (Borçlar):** Card, Overdrafts, Loan, Insurance → balance negatif/borç olarak gösterilir
- **Total:** Assets - |Liabilities|

```dart
enum AccountGroupType {
  cash(isAsset: true),
  accounts(isAsset: true),
  card(isAsset: false),         // Kredi kartı = liability
  debitCard(isAsset: true),
  savings(isAsset: true),
  topUpPrepaid(isAsset: true),
  investments(isAsset: true),
  overdrafts(isAsset: false),
  loan(isAsset: false),
  insurance(isAsset: false),    // Tartışmalı, tercihen toggle
  others(isAsset: true);
  // ...
}
```

### 7.4. Card Expenses Display Config (Ekran 5)
Kullanıcı Settings'ten seçer:
- **`at_the_time`** (varsayılan): Kredi kartı harcaması işlem tarihinde gösterilir
- **`on_payment_date`**: Kredi kartı harcaması, hesap kesim/ödeme tarihinde gösterilir (gerçek nakit etkisi anında)

Bu, raporlama ve bütçe hesaplamasında belirleyici. Faz 1 için **at_the_time** varsayılan; on_payment_date Faz 2.

### 7.5. Recurring Materializasyon
Tekrarlanan işlemler `recurring_transactions` tablosunda **şablon** olarak saklanır. Gerçek `transactions` kaydına şu zamanda dönüşür:
- **`reflectionTiming = on_the_date`:** Tarih geldiğinde otomatik (uygulama açıldığında veya background task ile)
- **`reflectionTiming = one_day_before`:** Bir gün önce
- **`reflectionTiming = on_app_open`:** Sadece uygulama açıldığında ve due tarihi geçmişse

Background scheduler `services/recurring_scheduler_service.dart` her uygulama açılışında ve günde bir kez (WorkManager / BGProcessingTask) çalışır:

```
for each recurring R where R.nextDueDate <= now and not R.isPaused:
  create new Transaction T from R
  R.installmentDone += 1
  if R.installmentCount != null and R.installmentDone >= R.installmentCount:
    R.endDate = R.nextDueDate
  else:
    R.nextDueDate = computeNextDueDate(R)
  save R
```

# SPEC — BÖLÜM 3: EKRAN EKRAN UI SPESİFİKASYONU

> Her ekran için: **layout, davranış, state akışı, edge case'ler, agent'a verilebilecek prompt formatında.** Ekranlar referans uygulamadaki numaralandırmaya göre değil, navigation hiyerarşisine göre düzenlenmiştir.

---

## 8. RENK VE TIPO REFERANSLARI (HATIRLATMA)

```
brandPrimary:   #FF6B5C  (coral/salmon — aktif tab, save, vurgular)
bgPrimary:      #1A1B1E  (en koyu arkaplan)
bgSecondary:    #24252A  (kart, modal, input)
bgTertiary:     #2E2F35  (seçili satır, hover)
textPrimary:    #FFFFFF
textSecondary:  #B0B3B8
textTertiary:   #6B6E76
income (mavi):  #4A90E2
expense (cor):  #FF6B5C
divider:        #2E2F35
```

---

## 9. EKRAN SPESİFİKASYONLARI

### 9.1. SCREEN: TransactionsScreen (Trans. tab) — Ekran 17, 18, 19, 20

**Route:** `/transactions`
**Komponent:** `lib/features/transactions/presentation/screens/transactions_screen.dart`

#### 9.1.1. AppBar (Üst)
- Sol: Arama ikonu (büyüteç) — tıklandığında SearchModal açar
- Orta: "Trans." başlığı (textPrimary, headline tipo)
- Sağ 1: Bookmark ikonu (yıldız + liste) — BookmarkPickerModal açar
- Sağ 2: Filter ikonu (3 yatay çubuk + nokta) — FilterModal açar
- Yükseklik: 56dp

#### 9.1.2. Ay/Yıl Navigatörü
- Solda `<` ok butonu → önceki ay
- Ortada "Apr 2026" (title2, beyaz, tıklanabilir → MonthYearPicker açar)
- Sağda `>` ok butonu → sonraki ay
- Yükseklik: 48dp
- Background: bgPrimary
- Aktif alt-tab "Monthly" iken sadece "2026" gösterilir (yıl)

#### 9.1.3. Alt-Tab Bar (5 sekme)
Yatay scrollable veya equal-flex:

| Tab | Label | Default | İçerik |
|---|---|---|---|
| 1 | "Daily" | İlk açılışta seçili | Liste: günlere göre gruplu işlemler |
| 2 | "Calendar" | - | Takvim grid |
| 3 | "Monthly" | - | Yıl içindeki ayların özeti |
| 4 | "Summary" | - | Yatay özet (Income/Exp/Total + Accounts + Budget) |
| 5 | "Description" | - | Açıklama bazlı arama (geçmiş kayıtlar) |

- Tab altında 2px alt-çizgi (aktif olanın altında brand renk)
- Inaktif: textSecondary, Aktif: textPrimary + alt çizgi

#### 9.1.4. Income / Exp / Total Özet Çubuğu
Tüm alt-tab'larda görünür (bazılarında):
```
| Income       Exp.        Total     |
|  0,00       651,13       -651,13   |  (income mavi, exp coral, total beyaz)
```
- Yükseklik: 60dp
- Solda Income (mavi), Ortada Exp. (coral), Sağda Total (beyaz, +/- işaretli)
- Tıklanabilir → o tipin filtreli görünümü

#### 9.1.5. Daily View (Ekran 20)
Liste yapısı:

**Gün başlığı satırı:**
- Sol: Gün numarası (büyük, beyaz, "27") + gün etiketi rozeti ("Mon" — küçük, gri arka)
- Pazar günleri için kırmızı rozet, Cumartesi için mavi rozet
- Sağ: Income (€ 0,00 mavi) + Expense (€ 53,95 coral)

**İşlem satırı (gün başlığının altında):**
- Sol kolon: Kategori adı (textSecondary, küçük) + Alt satır kategori adı (büyük) ya da emoji + kategori
- Orta: Hesap adı + tekrarlama bilgisi (gri "Bank Accounts(Every Month)")
- Sağ: Tutar (coral kırmızı, expense ise; mavi income ise)

**Floating Action Buttons (sağ alt):**
- Üstte: Bookmark/Liste ekleme (gri daire, ikon: liste + nokta)
- Altta: Ana `+` butonu (brand renk daire, beyaz +)
- İkisi 8dp ile ayrı

#### 9.1.6. Calendar View (Ekran 19)
- Üstte gün başlıkları: Mon, Tue, Wed, Thu, Fri, **Sat (mavi)**, **Sun (kırmızı)**
- Hücre yapısı:
  - Sol üst: Gün numarası (1, 2, 3, ... — bugünkü için açık beyaz arka, ileri günler textTertiary)
  - Orta-altta: Sadece harcama varsa toplam tutar (coral renk, küçük)
  - İki satır: Üst satır gelir mavi, alt satır gider coral (varsa)
  - Önceki/sonraki ay günleri textTertiary
- Tıklanan güne tıklayınca → DayDetailScreen veya bottom-sheet ile günün işlemleri açılır
- Sağ altta `+` FAB, brand renk

#### 9.1.7. Monthly View (Ekran 18)
- Yıl bazlı, her ay genişletilebilir kart:
  - Ay başlık satırı: "Apr / 1.4. ~ 30.4." | sağda Income, Expense, Total (€ -651,13)
  - Genişlediğinde haftalık alt satırlar:
    - "27.4. ~ 3.5." | "€ 0,00" | "€ 53,95" | sağda "€ -53,95"
  - Bugün haftası için light-coral arka plan vurgusu (Ekran 18'de görülüyor)

#### 9.1.8. Summary View (Ekran 17)
Yatay scrollable kart serisi:

**Card 1 — Top Stats:**
```
Income: 0,00       Exp.: 651,13       Total: -651,13
```

**Card 2 — Accounts:**
```
[icon] Accounts
┌─────────────────────────┐
│ Exp. (Cash, Accounts)   │
│              651,13     │
└─────────────────────────┘
```

**Card 3 — Budget:**
```
[icon] Budget
                          [Today indicator]
Total Budget          ▓░░░░░░░░ 0%
€ 0,00          0,00              0,00
```

**Card 4 — Aksiyon:**
```
┌──────────────────────────────────┐
│  📊 Export data to Excel         │
└──────────────────────────────────┘
```

- Sağ altta `+` FAB

#### 9.1.9. Description View
- İşlem açıklamalarına göre listeli/aranabilir görünüm
- Aynı açıklamayla birden fazla işlem grupla
- Faz 1.5'te eklenebilir (MVP'de opsiyonel)

#### 9.1.10. Floating Banner Ad (Ücretsiz tier)
- Alt tab'ın hemen üzerinde 50dp banner reklam
- Premium kullanıcıda gizlenir

---

### 9.2. SCREEN: AddTransactionScreen (Modal) — Ekran 1

**Route:** `/transactions/add` (modal route, presentation: bottom sheet üzerinden)
**Komponent:** `lib/features/transactions/presentation/screens/add_transaction_screen.dart`

#### 9.2.1. AppBar
- Sol: `<` Trans. (back butonu, "Trans." metni)
- Orta: "Income" / "Expense" / "Transfer" (aktif tipe göre değişir, başlık otomatik)
- Sağ: ⭐ Bookmark ikonu (kayıt formu doluyken kaydet bookmark olarak)

#### 9.2.2. Tip Seçici (3 toggle button)
```
┌───────────┐ ┌───────────┐ ┌───────────┐
│  Income   │ │ Expense   │ │ Transfer  │
│ (gri      │ │ (brand    │ │ (gri      │
│  border)  │ │  border)  │ │  border)  │
└───────────┘ └───────────┘ └───────────┘
```
- Yükseklik: 44dp
- Aktif: brandPrimary border + brandPrimary text
- İnaktif: textSecondary border + textSecondary text
- Background tüm hallerde bgSecondary

#### 9.2.3. Form Alanları (label-value satırları)

**Date satırı (Ekran 1):**
- Sol label: "Date" (textSecondary, body)
- Orta-sağ: "Tue 28.4.2026" (textPrimary, body, tıklanabilir)
- Sağ üst köşesi: Rep/Inst. ikonu (yenile-saat ikonu) — Repeat & Installment ayarlama
- Tıklanırsa DatePickerModal açılır (Cupertino-style spinner)

**Amount satırı:**
- Sol label: "Amount"
- Sağ: Tutar girişi (sayı klavyesi, başlangıçta boş, focus iken alt çizgi brand renk)
- Para birimi sembolü solda gösterilir (€, ₺, $)
- Hesap makinesi tetik: tutar focus'tayken AppBar sağ üstünde 🧮 ikon

**Category satırı:**
- Sol label: "Category"
- Sağ: Boş ise "" (placeholder), seçilince emoji + kategori adı
- Tıklanırsa CategoryPickerModal açılır

**Account satırı:**
- Sol label: "Account"
- Sağ: Hesap adı (örn. "Debit card") — varsayılan: en son kullanılan hesap
- Tıklanırsa AccountPickerModal açılır

**Note satırı:**
- Sol label: "Note"
- Sağ: TextField, placeholder boş, sonunda ⚠️ ikon (autocomplete açıksa)

**Description bölümü (alt, ayrı kart gibi):**
- Üstte ince divider
- Multi-line TextField, placeholder "Description"
- Sağda 📷 kamera ikonu (fotoğraf ekle)

#### 9.2.4. Aksiyon Butonları (alt)
İki yan yana buton:

```
┌──────────────────┐ ┌──────────────────┐
│      Save        │ │     Continue     │
│ (brand fill,     │ │ (border only,    │
│  beyaz yazı)     │ │  textSecondary)  │
└──────────────────┘ └──────────────────┘
   flex: 1.5            flex: 1
```

- Yükseklik: 52dp
- Save: işlemi kaydet ve modal'ı kapat
- Continue: işlemi kaydet ve formu reset'le aynı modal'da kal (sürekli giriş için)
- Save brand renkte, Continue ince outline

#### 9.2.5. Banner Reklam (alt)
Free user'da en altta, AppBar bottom safe-area üstünde.

#### 9.2.6. Validasyon
- Amount > 0
- Account zorunlu
- Category (transfer hariç) zorunlu
- Description, Note opsiyonel
- Save/Continue disabled iken görsel olarak da disabled (opacity 0.5)

#### 9.2.7. Davranış
```
on_save():
  validate()
  if (type == 'expense' || type == 'income'):
    transaction = Transaction(...)
    transactionRepository.add(transaction)
  else if (type == 'transfer'):
    transaction = Transaction(type: transfer, accountId: from, toAccountId: to, ...)
    transactionRepository.add(transaction)
  refreshAccountsBalances()
  refreshStats()
  navigator.pop()

on_continue():
  validate()
  save like above
  resetFormFields(keepAccount: true, keepCategory: true, keepDate: true)
```

---

### 9.3. SCREEN: StatsScreen (Stats tab) — Ekran 14, 15, 16

**Route:** `/stats`
**Komponent:** `lib/features/stats/presentation/screens/stats_screen.dart`

#### 9.3.1. Üst kontrol bar
Üst satır: 3 sub-tab toggle (segmented control benzeri):
```
┌──────────────────────────────┐  ┌────┐
│ Stats │ Budget │ Note        │  │ M ▼│
└──────────────────────────────┘  └────┘
```
- "Stats" / "Budget" / "Note" arasında geçiş — aktif olan brand fill
- Sağda "M ▼" period seçici dropdown: W (haftalık) / M (aylık) / Y (yıllık) / Period (özel)

#### 9.3.2. Ay navigasyonu (Ekran 16)
- < Apr 2026 > standart yapı

#### 9.3.3. Income / Exp Toggle
İki seçenek:
- Income (textSecondary)
- Exp. € 651,13 (aktif: textPrimary, alt çizgi brand renk + tutar gösterimi)

#### 9.3.4. Stats Sub-tab içeriği (Ekran 16)
**Pasta grafiği (Top, ~ 360dp height):**
- Donut/pie chart, fl_chart kullan
- Her dilim: brand renk paleti'nden (kırmızı, turuncu, sarı, yeşil, mavi, mor — referans renkler)
- Çevresinde label + yüzde (Restaurant 30.5%, Groceries 25.1%, vs.)
- Dilime tıkla → o kategorinin transactions'a yönlendir

**Liste (alt):**
Her satır:
```
[%30 brand renk badge] [emoji] Restaurant ............... € 198,44
[%25 brand renk badge] [emoji] Groceries ................ € 163,55
...
```
- Yüzde rozeti sol: pasta dilimi rengi ile aynı (renkli arka, beyaz yazı)
- Kategori: emoji + ad
- Sağ: tutar (textPrimary)

#### 9.3.5. Budget Sub-tab içeriği (Ekran 15)
**Üstte özet kartı:**
```
Remaining (Monthly)         [Budget Setting >]
€ 0,00

Monthly        ░░░░░░░ Today indicator   0%
€ 0,00         0,00                      0,00
```

**Alt liste (kategori bazlı bütçe ilerlemeleri):**
Her kategori için:
- Sol: emoji + kategori adı
- Sağ: harcanan tutar
- Bütçe varsa: harcanan/bütçe oranını gösteren ilerleme çubuğu (renkli, eşik aşıldıysa kırmızı)

#### 9.3.6. Note Sub-tab içeriği (Ekran 14)
- Açıklamaya göre gruplanmış işlem özeti
- 3 sütunlu liste başlığı: "Note" | "↓9 1" (sıralama: amount yüksekten düşüğe) | "Amount"
- Satırlar: "O2 (description)" | "1" (kullanım sayısı) | "€ 14,11"
- Boş açıklamalı işlemler en üstte birleşik gösterilir

---

### 9.4. SCREEN: AccountsScreen (Accounts tab) — Ekran 13

**Route:** `/accounts`
**Komponent:** `lib/features/accounts/presentation/screens/accounts_screen.dart`

#### 9.4.1. AppBar
- Orta: "Accounts" başlığı
- Sağ 1: Edit ikonu (kalem) — multi-select edit moduna geç
- Sağ 2: `+` ikonu — yeni hesap ekle

#### 9.4.2. Üst Özet Bar
3 sütun:
```
Assets         Liabilities       Total
0,00 (mavi)    0,00 (kırmızı)    0,00 (beyaz)
```

#### 9.4.3. Hesap grupları + hesaplar (collapsible)
Her grup başlığı (Account Group):
```
[grup adı]                           [bakiye]
```
- Tıklanırsa expand/collapse

Her hesap satırı:
- Sol: Hesap adı (textPrimary, biraz girintili)
- Orta: küçük gri istatistik (örn. son işlem tarihi, opsiyonel)
- Sağ: bakiye (€ 0,00) — pozitif beyaz, negatif kırmızı

#### 9.4.4. Banner reklam alt
- Revolut benzeri (Ekran 13'te görünüyor)

#### 9.4.5. Hesap satırına tıklama
→ AccountDetailScreen: o hesabın işlemleri liste halinde + bakiye trendi grafiği

---

### 9.5. SCREEN: AccountAddEditScreen — Ekran 12

**Route:** `/accounts/add` veya `/accounts/edit/:id`
**Komponent:** `lib/features/accounts/presentation/screens/account_add_edit_screen.dart`

#### 9.5.1. AppBar
- Sol: `<` Accounts (back)
- Orta: yok (veya "Add"/"Edit")
- Sağ: "Add" / "Save" buton (brand renk text)

#### 9.5.2. Form
3 alan üst üste:

**Group:**
- Tıklanınca Account Group picker bottom-sheet açılır (Ekran 12 alt yarısı)
- Picker içeriği:
  ```
  Account Group
  ─────────────
  Cash
  Accounts
  Card
  Debit Card
  Savings
  Top-Up/Prepaid
  Investments
  Overdrafts
  Loan
  Insurance
  Others
  ─────────────
  Cancel
  ```
- Her grup tıklanınca seçilir, sheet kapanır

**Name:**
- TextField, placeholder "Name"

**Amount:**
- Initial balance girişi
- Para birimi (Main Currency varsayılan, ama değiştirilebilir → currency picker)

#### 9.5.3. Ek alanlar (grup tipine göre dinamik)
- **Card seçilirse:** Statement Day (1-31), Payment Due Day (1-31), Credit Limit
- **Savings/Investment:** Faiz oranı, vade tarihi (opsiyonel, Faz 2)
- **Loan:** Toplam borç, taksit sayısı, taksit tutarı (Faz 2)

---

# SPEC — BÖLÜM 4: MORE TAB & SETTINGS EKRANLARI

---

### 9.6. SCREEN: MoreScreen (More tab) — Ekran 10, 11

**Route:** `/more`
**Komponent:** `lib/features/more/presentation/screens/more_screen.dart`

#### 9.6.1. AppBar
- Orta: "Settings"
- Sağ üst: Versiyon bilgisi "2.12.3 AF" (textTertiary, küçük, dokunulamaz)

#### 9.6.2. Section yapısı
Liste birden çok bölüme ayrılır. Her bölümün üstünde kalın arka planlı separator:

**Bölüm 1 — (Üst, başlıksız):**
- 🧮 CalcBox (Realbyte'ın diğer uygulaması — *biz kendi muadilimizi çıkartırız ya da kaldırırız*)
- 💻 PC Manager
- ❓ Help
- 📩 Feedback
- ❤️ Rate it
- 🚫 Remove Ads.

**Bölüm 2 — Trans.:**
- 📝 Transaction Settings (alt başlık: "Monthly Start Date, Carry-over Setting, Period, Other")
- 🔁 Repeat Setting
- 📋 Copy-Paste Settings

**Bölüm 3 — Category/Accounts:**
- 💰+ Income Category Setting
- 💰- Expenses Category Setting
- 💼 Accounts Setting (alt başlık: "Account Group, Accounts, Include in totals, Transfer-Expense...")
- 💵 Budget Setting

**Bölüm 4 — Settings:**
- 🔄 Backup (alt: "Export, Import, A complete reset")
- 🔒 Passcode (sağda durum: "OFF" / "ON")
- 💵 Main Currency Setting (alt: "EUR(€)")
- 💵+ Sub Currency Setting
- 🔔 Alarm Setting
- 🎨 Style
- 🚀 Application Icon
- 🌐 Language Setting

Her satır:
- Sol: ikon (32x32, textSecondary)
- Orta: ana başlık (textPrimary, body) + alt başlık (textTertiary, footnote, opsiyonel)
- Sağ: değer (textSecondary) + chevron `>` veya toggle veya doğrudan klikable

---

### 9.7. SCREEN: TransactionSettingsScreen — Ekran 9

**Route:** `/more/transaction-settings`

#### 9.7.1. Ayarlar listesi

| Setting | Tip | Default | Açıklama |
|---|---|---|---|
| Monthly Start Date | numeric (1-31) | 1 | Aylık dönemin başlangıç günü |
| Weekly Start Day | enum | Monday | Haftanın ilk günü (Mon-Sun) |
| Carry-over Setting | bool | Off | Bütçenin kalan kısmı sonraki aya devretsin mi |
| Period Setting | enum | Monthly | Default zaman dilimi (Weekly/Monthly/Annually) |
| Income-Expenses Color Setting | enum | Exp. (vurgu Exp.) | Hangi rengin daha belirgin gösterileceği |
| Autocomplete | bool | On | Description/Note için otomatik tamamlama |
| Time Input | enum | None, Desc. | İşleme saat eklensin mi (None / With time) |
| Start Screen (Daily/Calendar) | enum | Daily | Trans. tab'a girince başlangıç görünüm |
| Swipe | enum | To Change Date | Sağ/sol kaydırma davranışı |
| Show description | bool | Off | Listede description gösterilsin mi |
| Input order | enum | From Amount | Form alan sırası |
| Note button setting | bool | On | Add Transaction'da Note butonu görünsün mü |

Her satır tıklanınca uygun picker (bottom sheet) açılır.

---

### 9.8. SCREEN: RepeatSettingsScreen — Ekran 8

**Route:** `/more/repeat-settings`

#### 9.8.1. AppBar
- Sol: `<` Settings
- Orta: "Repeat Setting"
- Sağ 1: 🗑️ Trash (multi-select delete moduna geç)
- Sağ 2: `+` (yeni recurring template ekle)

#### 9.8.2. İçerik
**Üstte ayar:**
```
Timing of reflection                  On the date  >
```
- Tıklanırsa picker: 'On the date' / 'One day before' / 'On app open'

**Altta listeleme (gelir/gider tipine göre gruplu):**
```
Exp.                                                € 48,00
─────────────────────────────────────
27.5.        Gas
Every Month  Bills    Bank Accounts                € 12,00
─────────────────────────────────────
27.5.        Electricity
Every Month  Bills    Bank Accounts                € 36,00
```

Satır yapısı:
- Sol: bir sonraki due tarihi (kalın) + frekans (textTertiary)
- Orta üst: işlem adı (örn. "Gas")
- Orta alt: kategori + hesap (textTertiary)
- Sağ: tutar (coral)

#### 9.8.3. Yeni Recurring Ekleme Formu
Add Transaction formuna benzer ama ek olarak:
- Frequency: Daily / Weekly / Monthly / Yearly / Custom
- Interval (Every N)
- Day of month / Day of week (frequency'ye göre)
- Start Date
- End Date (optional)
- Installment Count (optional, taksitli için)

---

### 9.9. SCREEN: CategoryManagementScreen (Income / Expense) — Ekran 6, 7

**Route:** `/more/category-management?type=income` veya `?type=expense`

#### 9.9.1. AppBar
- Sol: `<` Settings
- Orta: "Income" veya "Exp."
- Sağ: `+` (yeni kategori ekle)

#### 9.9.2. Üstte toggle
```
Subcategory                                    [○ ─]
```
- ON ise her kategoride sub-category göstermek için expand/collapse okları görünür
- OFF ise sadece ana kategoriler düz liste

#### 9.9.3. Liste
Her satır:
- Sol: 🔴 Sil ikonu (kırmızı daire içinde -)
- Orta: emoji + kategori adı
- Sağ 1: ✏️ Edit ikonu (kalem)
- Sağ 2: ☰ Drag handle (sıralama için)

**Income default kategoriler (Ekran 7):**
🤑 Allowance, 💰 Salary, 💵 Petty cash, 🥇 Bonus, Other, 💸 Dividend, 💸 Interest

**Expense default kategoriler (Ekran 6):**
🍜 Food, 👫 Social Life, 🐶 Pets, 🚕 Transport, 🖼️ Culture, 🪑 Household, 🧥 Apparel, 💄 Beauty, 🧘 Health, 📚 Education, 🎁 Gift, Other, 🤵 Insurance, 🏠 Rent, 🚬 Cigarette, ...

#### 9.9.4. Edit/Add Modal
Tıklanınca veya `+` ile açılır:
- TextField: Kategori adı
- Emoji picker (native iOS/Android emoji veya kütüphane: `emoji_picker_flutter`)
- Color picker (palet)
- Sub-category olarak işaretle (ana kategori seç)

#### 9.9.5. Silme davranışı
- Satırdaki 🔴 ikonu ya da swipe-to-delete
- Onay diyalogu: "Bu kategoriye ait X işlem var. Ne yapmak istersiniz?"
  - "Other" kategorisine taşı
  - Hepsini sil
  - İptal

---

### 9.10. SCREEN: AccountSettingsScreen — Ekran 5

**Route:** `/more/accounts-settings`

#### 9.10.1. Liste
- Account Group → AccountGroupManagementScreen
- Accounts Setting → AccountListScreen (rearrange/edit)
- Include in totals → toggle list (her account için)
- Transfer-Expense setting → açıklamalı toggle (transfer'in expense olarak da sayılması)
- Deleted accounts → silinmiş hesaplar arşivi
- **Card expenses display config: A. At the time** (sağda değer)
  - Tıklanırsa: 'At the time' / 'On payment date' picker

---

### 9.11. SCREEN: BudgetSettingScreen — Ekran 4

**Route:** `/more/budget-setting`

#### 9.11.1. AppBar
- Sol: `<` Settings
- Orta: "Budget Setting"
- Sağ: "M ▼" period toggle (W/M/Y)

#### 9.11.2. Ay navigatörü
- < Apr 2026 >

#### 9.11.3. Income / Exp toggle
İki segment, varsayılan Exp.

#### 9.11.4. Kategori listesi
Her kategori için:
```
[emoji] Kategori adı                          € 0,00 >
```
- Tıklanınca BudgetEditModal:
  - "Bütçe tutarı:" input
  - "Bu sadece bu ay için" checkbox (tikli değilse → tüm sonraki aylar için varsayılan)
  - Save/Cancel

#### 9.11.5. Liste başlangıcı
İlk satır: TOTAL (overall) bütçe (kategori = null)

---

### 9.12. SCREEN: BackupScreen

**Route:** `/more/backup`

#### 9.12.1. Bölümler

**Section 1 — Cloud Backup:**
- Google Drive (toggle ON/OFF + frequency: Daily/Weekly/Manual)
- iCloud (iOS only, otomatik eğer iCloud Drive aktifse)
- Last backup: timestamp

**Section 2 — Local Backup:**
- Backup to Device → bir .db dosyası oluştur
- Restore from Device → file picker
- Backup to Email → mailto: ile attachment

**Section 3 — Excel:**
- Export to Excel (.xlsx) → file_picker save dialog
- Import from Excel → format guide modali + file picker

**Section 4 — Reset:**
- A complete reset (kırmızı yazı, onay diyalogu çift adımlı)

---

### 9.13. SCREEN: PasscodeScreen

**Route:** `/more/passcode`

#### 9.13.1. Setup akışı (Passcode OFF iken)
1. "Enable Passcode" toggle aç → 4-digit numeric input ekranı
2. Tekrar gir (Confirm) → eşleşirse hash'le ve kaydet
3. Biyometrik prompt: "Use FaceID/TouchID?"
4. Passcode Prompt Frequency seçici: Always / After 5 min / After 30 min

#### 9.13.2. Aktif iken
- Passcode değiştir (eski + yeni)
- Biyometrik toggle
- Frequency değiştir
- Passcode'u kapat (eski passcode + onay)

#### 9.13.3. Lock Screen
Uygulama açılışında veya 5dk inaktivite sonrası:
- 4 nokta UI
- Numpad
- Sağ alt: 🤳 biyometrik ikonu (etkinse)
- Yanlış 5 kez → 1dk timeout

---

### 9.14. SCREEN: StyleScreen — Ekran 3

**Route:** `/more/style`

```
[icon] System Mode    [○]
[icon] Dark Mode      [●]  ← seçili (brand fill)
[icon] Light Mode     [○]
```

- Radio button benzeri (sağda daire)
- Aktif olan brand renk dolgu, diğerleri border-only

---

### 9.15. SCREEN: LanguageScreen — Ekran 2

**Route:** `/more/language`

Bottom-sheet modali olarak açılır (slide up).

```
Language Setting
─────────────────────────────
Bahasa Indonesia
Deutsch
English                  ✓ (brand renkli check)
Español
Français
Italia
Polski
Português
Русский
Românesc
Türkçe
Tiếng Việt
Українська
বাঙালি
... (scrollable, tüm diller)
─────────────────────────────
Cancel
```

- Aktif dilin yazısı brand renk + sağda check
- Faz 1 desteklenen: TR, EN, DE, ES (Türkçe en üst sıralarda olmalı popülerlik için)
- Diğerleri Faz 2+

---

### 9.16. SCREEN: CurrencyScreen (Main + Sub)

**Route:** `/more/currency-main` ve `/more/currency-sub`

#### 9.16.1. Main Currency
- Tek seçim
- Liste: TRY, EUR, USD, GBP, JPY, ... (ISO 4217)
- Her satır: Bayrak + Code + Name + Symbol
- Aktif olan brand renk + check
- Arama bar üstte

#### 9.16.2. Sub Currency
- Çoklu seçim (kullanıcı birden fazla ek para birimi tutabilir)
- Her satırda toggle
- Per-currency exchange rate inline edit (kullanıcı kendi rate'ini set edebilir)
- API'den otomatik fetch butonu (FX API ile, Faz 2)

---

### 9.17. SCREEN: AlarmScreen

**Route:** `/more/alarm`

- "Daily Reminder" toggle
- Saat picker (varsayılan 21:00)
- "Bugün hala işlem girmediniz" gibi yerel bildirim
- "Repeating transactions Today" otomatik bildirim toggle

---

### 9.18. SCREEN: PremiumScreen (Remove Ads)

**Route:** `/more/premium`

#### 9.18.1. Üst görsel
- App icon büyük + "MoneyWise Premium" başlığı

#### 9.18.2. Özellikler
Liste:
- ✓ Reklamsız deneyim
- ✓ Sınırsız hesap (free: 15 ile sınırlı)
- ✓ Cloud Sync (cihazlar arası)
- ✓ Premium tema desteği
- ✓ PC Manager (Web app erişimi)
- ✓ Öncelikli destek

#### 9.18.3. Fiyatlandırma kartları
```
┌──────────────────────────┐
│  💎 Lifetime Premium     │
│        ₺149,99           │
│   Tek seferlik ödeme     │
│   [Buy Now]              │
└──────────────────────────┘

┌──────────────────────────┐
│  ☁️ Cloud Sync           │
│  Aylık ₺29 / Yıllık ₺199 │
│  ★ İlk ay ücretsiz       │
│   [Subscribe]            │
└──────────────────────────┘
```

#### 9.18.4. Restore Purchases linki

---

### 9.19. SCREEN: HelpScreen / FeedbackScreen

- Help: Statik sayfa veya WebView (yardım merkezi URL'ine)
- Feedback: TextArea + email subject + Send butonu (mailto: veya internal endpoint)

---

### 9.20. SCREEN: PCManagerScreen (Faz 3)

- Web app QR kod
- Bağlantı bilgileri
- Wi-Fi connection setup
- Local network Wi-Fi'da çalışan basit web server (Faz 3 gerçekleştirilecekse)

---

# SPEC — BÖLÜM 5: KALİTE, CI/CD, AGENT ROLLERİ VE YOL HARİTASI

---

## 10. STATE MANAGEMENT KURALLARI (RIVERPOD)

### 10.1. Provider Tipleri Kullanım Rehberi

| Provider | Kullanım |
|---|---|
| `Provider` | Stateless servisler, repository'ler |
| `StateProvider` | Tek değer state (örn. seçili tab index) |
| `StateNotifierProvider` | Karmaşık state + business logic |
| `FutureProvider` | One-shot async (örn. ilk balance fetch) |
| `StreamProvider` | Reactive Drift query (her insert/update'te yeniden tetiklenir) |
| `AsyncNotifierProvider` (Riverpod 2.5+) | Modern, code-gen ile loading/error handling |

### 10.2. Provider Code-Gen
`riverpod_generator` ve `freezed` kullanın:

```dart
// account_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_provider.g.dart';

@riverpod
Stream<List<Account>> accountsList(AccountsListRef ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
}

@riverpod
class TransactionForm extends _$TransactionForm {
  @override
  TransactionFormState build() => const TransactionFormState.initial();

  void setType(TransactionType type) => state = state.copyWith(type: type);
  void setAmount(double amount) => state = state.copyWith(amount: amount);

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(transactionRepositoryProvider).add(state.toTransaction());
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }
}
```

### 10.3. Reactive UI
Listeler her zaman `StreamProvider` üzerinden Drift'e bağlı. Yeni transaction eklenince hesap bakiyeleri ve listeler otomatik yenilenir.

```dart
// transactions_screen.dart
class DailyView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(transactionsByMonthProvider(selectedMonth));

    return transactions.when(
      data: (txList) => _buildList(txList),
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(error: e),
    );
  }
}
```

---

## 11. TEST STRATEJİSİ

### 11.1. Test Piramidi
```
       /\
      /E2E\           5%   (integration_test, en kritik akışlar)
     /─────\
    / Widget \       25%   (UI bileşenleri ve ekran)
   /─────────\
  /   Unit    \      70%   (entity, usecase, repository, formatter)
 /─────────────\
```

### 11.2. Test Klasörü
```
test/
├── core/
│   ├── extensions/
│   ├── utils/
│   │   ├── currency_formatter_test.dart
│   │   └── date_helpers_test.dart
│   └── widgets/
│       └── currency_text_test.dart
├── data/
│   ├── repositories/
│   │   ├── account_repository_test.dart
│   │   └── transaction_repository_test.dart
│   └── local/
│       └── database_test.dart
├── domain/
│   ├── entities/
│   │   ├── money_test.dart
│   │   └── transaction_test.dart
│   └── usecases/
│       ├── add_transaction_test.dart
│       ├── transfer_between_accounts_test.dart
│       └── carry_over_budget_test.dart
└── features/
    ├── transactions/
    │   ├── add_transaction_provider_test.dart
    │   └── transactions_screen_test.dart
    └── stats/
        └── pie_chart_widget_test.dart

integration_test/
├── add_expense_flow_test.dart
├── transfer_flow_test.dart
├── budget_setup_flow_test.dart
├── backup_restore_flow_test.dart
└── passcode_flow_test.dart
```

### 11.3. Mocking Stratejisi
- **Repository'ler:** mocktail ile mock
- **Drift:** `NativeDatabase.memory()` ile in-memory test DB
- **Riverpod:** `ProviderContainer` ile override

### 11.4. Coverage Hedefleri
- Domain layer (entities, usecases): **min %90**
- Data layer (repositories, daos): **min %80**
- Features (providers): **min %70**
- Widgets: **min %50**
- Genel toplam: **min %75**

CI'da `flutter test --coverage` çalışır, %75 altına düşerse PR red edilir.

---

## 12. CI/CD PIPELINE

### 12.1. GitHub Actions İş Akışları

`.github/workflows/`:

#### 12.1.1. `pr_checks.yml` — Her PR'da
```yaml
name: PR Checks
on:
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: 'stable'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
```

#### 12.1.2. `build_android.yml` — develop ve main'e merge'de
```yaml
name: Build Android
on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: 'temurin' }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --flavor dev --release
      - run: flutter build appbundle --flavor prod --release
      - name: Distribute via Firebase
        run: # firebase app:distribute ...
```

#### 12.1.3. `build_ios.yml` — main'e merge'de
- macOS runner
- Xcode setup
- Code signing (App Store Connect API key)
- TestFlight upload via fastlane

#### 12.1.4. `release.yml` — Tag push'unda
- Production build
- Store upload (Google Play + App Store)
- GitHub Release oluştur (changelog ile)

### 12.2. Branch Stratejisi
- `main` → Production (App Store + Google Play)
- `develop` → Internal beta (TestFlight + Firebase App Distribution)
- `feature/*` → Geliştirme dalları
- `hotfix/*` → Acil düzeltmeler
- `release/*` → Versiyon hazırlık

### 12.3. Versionlama
Semantic Versioning: `MAJOR.MINOR.PATCH+BUILD`
- pubspec.yaml: `version: 1.0.0+1`
- Her build'de BUILD otomatik artar (CI)
- MAJOR, MINOR, PATCH manuel güncellenir

### 12.4. Çevreler (Environments)

`lib/core/config/env.dart`:
```dart
enum Environment { dev, staging, prod }

class Env {
  static late Environment current;
  static late String supabaseUrl;
  static late String supabaseAnonKey;
  static late String sentryDsn;
  // ...

  static Future<void> load(Environment env) async {
    current = env;
    final fileName = '.env.${env.name}';
    await dotenv.load(fileName: fileName);
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    // ...
  }
}
```

`main_dev.dart`, `main_staging.dart`, `main_prod.dart` — flavors için entry points.

---

## 13. GÜVENLİK VE PRIVACY

### 13.1. Lokal Veri Güvenliği
- Drift DB **SQLCipher** ile şifrelenmeli (AES-256)
- Encryption key cihaz keychain'inde (`flutter_secure_storage`)
- İlk kurulumda otomatik key üretilir, kullanıcı görmez
- Backup dosyaları aynı key ile şifrelenir, kullanıcının dışa aktardığı dosyada kullanıcı dostu passphrase opsiyonu

### 13.2. Network Güvenliği
- Tüm API çağrıları HTTPS
- Certificate Pinning (Supabase için public key)
- API anahtarları .env'de, repo'ya commitlenmez

### 13.3. Authentication
- Supabase Auth: email + password (Argon2id) veya OAuth (Apple, Google)
- Apple Sign-In zorunlu (Apple Store policy)
- Token refresh otomatik

### 13.4. KVKK / GDPR Uyumluluğu
- Privacy Policy ekranı (HelpScreen içinde link)
- "Verilerimi sil" butonu (Settings > Account > Delete account)
- Account deletion endpoint: `DELETE /user/{id}` (server-side cascade)
- Veri taşınabilirliği: Excel export her zaman ücretsiz

### 13.5. App Store / Play Store Privacy Manifest
- iOS Privacy Manifest (`PrivacyInfo.xcprivacy`)
- Google Play Data Safety Form
- Toplanan veri: Email (auth için), App usage (analytics, opsiyonel)
- Toplanmayan: Konum, kişiler, sağlık, finans bilgileri (banka API yok)

### 13.6. Reklam Privacy
- AdMob için ATT (App Tracking Transparency) prompt iOS 14+
- GDPR Consent (UMP SDK)

---

## 14. KABUL KRİTERLERİ (DEFINITION OF DONE)

Her özelliğin "tamamlandı" sayılması için:

- [ ] Kod yazıldı, lint hatası yok (flutter analyze temiz)
- [ ] Unit test'ler yazıldı, coverage hedefleri tutturuldu
- [ ] Widget test'ler yazıldı (önemli ekranlar için)
- [ ] Spec dokümanındaki davranışa uygun
- [ ] Hem light hem dark tema test edildi
- [ ] iOS ve Android'de manuel test geçti
- [ ] i18n: TR ve EN çevirileri eksiksiz
- [ ] Accessibility: minimum tap target 44x44, semantic labels
- [ ] Performance: 60fps koruyor (DevTools profile)
- [ ] Code review onaylandı (en az 1 reviewer)
- [ ] Merge sonrası CI/CD yeşil
- [ ] PR description'da ekran görüntüleri/video var

---

## 15. CLAUDE CODE AGENT ROLLERİ VE GÖREV DAĞILIMI

Bu projeyi Claude Code üzerinde çalıştırırken aşağıdaki agent yapılandırmasını kullanın. Her agent'a verilecek system prompt ve sorumluluk alanı net olmalı.

### 15.1. AGENT 1: `product-manager`

**System Prompt:**
> Sen Money Manager klonu projesinin Product Manager'ısın. SPEC.md dosyasını referans alarak: kullanıcı hikayeleri yaz, sprint planlaması yap, özellik önceliklendirmesi yap, edge-case'leri tespit et, kabul kriterleri yaz. Kod yazma — sadece dokümantasyon, GitHub issue, ve PR yorum'larıyla iletişim kur. Türkçe ve İngilizce arasında geçiş yapabilirsin.

**Görevleri:**
- User Story'leri yaz (`/docs/user_stories/`)
- Sprint backlog hazırla (`/docs/sprints/sprint_NN.md`)
- GitHub issue'ları oluştur (template: feature.md, bug.md)
- Kabul kriterlerini her issue'ya ekle
- Roadmap'i güncelle (`/docs/ROADMAP.md`)
- Edge case ve hata akışlarını dokümantize et

**Çıktı tipi:** Markdown dosyaları, GitHub issue'lar

### 15.2. AGENT 2: `flutter-engineer`

**System Prompt:**
> Sen kıdemli Flutter mühendisisin. Money Manager klonu projesi için Flutter/Dart kodu yazıyorsun. SPEC.md'deki mimariye, isimlendirme konvansiyonuna ve teknoloji seçimlerine birebir uy. Riverpod, Drift, go_router kullan. Code-gen ile çalış (`build_runner build`). Her özelliği önce klasör yapısı + boş dosyalar olarak çıkartıp sonra implementasyona geç. Tek dosya tek sorumluluk. 200 satırı geçen widget'ları parçala. Asla iş mantığını widget içine yazma — usecase ve provider'a koy.

**Görevleri:**
- Klasör yapısını oluştur
- `pubspec.yaml` doldur
- Drift tablolarını yaz
- Repository ve DAO'ları yaz
- Domain entity'ler ve usecase'ler
- Riverpod provider'ları
- UI widget'ları ve ekranları
- i18n ARB dosyaları
- `build_runner` çalıştır

**Çıktı tipi:** `.dart`, `.yaml`, `.arb` dosyaları

**Kısıtlamalar:**
- Hiçbir zaman doğrudan `runApp()` çağırma — `bootstrap.dart`'tan geçir
- TextStyle'ları inline yazma — `AppTypography` üzerinden
- Color'ları inline yazma — `AppColors` üzerinden
- `setState()` kullanma — Riverpod ile yönet
- `BuildContext` async gap'lerden geçirme

### 15.3. AGENT 3: `code-reviewer`

**System Prompt:**
> Sen senior code reviewer'sın. Flutter, Dart, Clean Architecture, SOLID, DRY, performance, ve güvenlik konularında uzman. Sana gönderilen her PR'ı/dosyayı Money Manager projesi SPEC.md ve kod standartlarına göre incele. Yorumları yapıcı ve aksiyon alınabilir şekilde yaz. Her yorum için: (1) ne sorunlu, (2) neden sorunlu, (3) nasıl düzeltilmeli — somut kod önerisi ile. Asla "iyi görünüyor" demekle yetinme — bir şeyler her zaman iyileştirilebilir. Test kapsamını, performansı, accessibility'i, i18n'i ve güvenlik açıklarını ayrıca kontrol et.

**Görevleri:**
- PR yorumları (GitHub PR review formatında)
- Code smell tespiti
- Performance issue tespiti
- Security audit
- Test kapsamı kontrolü
- Naming convention check
- Spec compliance check

**Çıktı tipi:** GitHub PR yorumları (inline + summary)

**Kontrol Listesi:**
- [ ] SPEC'e uyuyor mu?
- [ ] Test var mı? Yeterli mi?
- [ ] Lint geçiyor mu?
- [ ] Naming convention?
- [ ] Magic number/string var mı?
- [ ] Error handling?
- [ ] Loading state?
- [ ] Empty state?
- [ ] i18n?
- [ ] Accessibility (semanticsLabel)?
- [ ] Performance (rebuild minimization)?
- [ ] Memory leak (dispose, cancel)?

### 15.4. AGENT 4: `devops-engineer`

**System Prompt:**
> Sen DevOps mühendisisin. Money Manager projesinin CI/CD, dağıtım, çevre yönetimi, monitoring ve altyapısından sorumlusun. GitHub Actions, fastlane, Firebase, Supabase, App Store Connect, Google Play Console konularında uzman. SPEC.md'deki Bölüm 12 ve 13'e sadık kal.

**Görevleri:**
- `.github/workflows/` dosyalarını yaz
- Fastlane (`fastlane/Fastfile`) konfigürasyonu
- Firebase project setup script'leri
- Supabase migration dosyaları (`supabase/migrations/`)
- Environment dosyaları (`.env.dev`, `.env.staging`, `.env.prod` template)
- Build flavors (Android: build.gradle, iOS: xcconfig)
- App Store / Play Store metadata (`fastlane/metadata/`)
- Crashlytics / Sentry setup
- Code signing (manage match repo)
- Release notes otomasyonu

**Çıktı tipi:** YAML, Ruby (fastlane), shell script, config dosyaları

### 15.5. AGENT KOORDİNASYON AKIŞI

```
┌─────────────────┐
│ product-manager │ → User Story #42 + Acceptance Criteria
└────────┬────────┘
         ↓ (issue açar)
┌──────────────────────────────────┐
│ flutter-engineer                 │ → Branch açar, kod yazar
└────────┬─────────────────────────┘
         ↓ (PR açar)
┌──────────────────┐
│ code-reviewer    │ → PR'ı inceler, yorum yazar
└────────┬─────────┘
         ↓ (onay verirse)
┌─────────────────┐
│ flutter-engineer│ → Yorumları çözer, push eder
└────────┬────────┘
         ↓ (re-review onay)
┌──────────────────┐
│ devops-engineer  │ → CI yeşil, merge edilir, deploy
└──────────────────┘
```

**Önerilen iş akışı (Claude Code'da):**
1. `product-manager` agent'ı bir feature için issue açar
2. Sen veya `flutter-engineer` agent'ı yeni bir feature branch oluşturur
3. `flutter-engineer` kodu yazar
4. Sen test eder, sonra `code-reviewer` agent'ından PR review iste
5. Yorumları `flutter-engineer` ile çöz
6. `devops-engineer` ile CI/CD pipeline'ı doğrula

---

## 16. YOL HARİTASI VE SPRINT PLANI

### 16.1. Faz 1 — MVP (8 Sprint, 16 hafta, 2 hafta/sprint)

#### Sprint 1: Proje Kurulumu
- [ ] Flutter proje oluştur (flavors: dev, staging, prod)
- [ ] Klasör yapısı oluştur (Bölüm 5'e göre)
- [ ] pubspec.yaml + tüm dependencies
- [ ] CI/CD temel pipeline (lint + test + build)
- [ ] Drift DB initial migration
- [ ] Theme + Color + Typography system
- [ ] go_router kurulumu, ana 4 tab navigation
- [ ] Boş ekran scaffold'ları (placeholder)
- [ ] i18n setup (TR + EN)

#### Sprint 2: Hesap & Kategori Yönetimi
- [ ] AccountGroup CRUD
- [ ] Account CRUD (Add/Edit/Delete/Hide)
- [ ] Default account groups + categories seed
- [ ] AccountsScreen (Ekran 13)
- [ ] CategoryManagementScreen (Ekran 6, 7)
- [ ] AccountAddEditScreen (Ekran 12)
- [ ] Multi-currency setup (Main + Sub)

#### Sprint 3: Transaction CRUD (En Kritik!)
- [ ] Transaction tablosu + DAO
- [ ] AddTransactionScreen (Income/Expense/Transfer) (Ekran 1)
- [ ] CategoryPicker, AccountPicker, DatePicker modalları
- [ ] Calculator widget (input field içinde)
- [ ] Save & Continue buton mantığı
- [ ] Transfer mantığı (atomik, çift kayıt)
- [ ] Account balance computed stream

#### Sprint 4: Trans. Tab Görünümleri
- [ ] TransactionsScreen scaffold
- [ ] DailyView (Ekran 20)
- [ ] CalendarView (Ekran 19)
- [ ] MonthlyView (Ekran 18)
- [ ] SummaryView (Ekran 17)
- [ ] Month/Year navigator
- [ ] Period tabs (Daily/Calendar/Monthly/Summary)

#### Sprint 5: Stats & Budget
- [ ] StatsScreen ile pie chart (fl_chart) (Ekran 16)
- [ ] BudgetView (Ekran 15)
- [ ] NoteView (Ekran 14)
- [ ] BudgetSettingScreen (Ekran 4)
- [ ] Budget CRUD + carry-over mantığı

#### Sprint 6: More Tab & Settings
- [ ] MoreScreen (Ekran 10, 11)
- [ ] TransactionSettingsScreen (Ekran 9)
- [ ] StyleScreen (Ekran 3)
- [ ] LanguageScreen (Ekran 2)
- [ ] CurrencyScreen (Main + Sub)
- [ ] Tüm settings'in persistance'ı

#### Sprint 7: Recurring & Bookmark
- [ ] Bookmarks CRUD
- [ ] BookmarkPickerModal (AddTransaction'dan açılır)
- [ ] RecurringTransactions CRUD
- [ ] RepeatSettingsScreen (Ekran 8)
- [ ] Recurring scheduler service (background materializasyon)
- [ ] Local notification (recurring due hatırlatıcı)

#### Sprint 8: Backup, Passcode, Polish
- [ ] BackupScreen (Excel export/import)
- [ ] Local file backup/restore
- [ ] PasscodeScreen + lock screen
- [ ] Biometric auth
- [ ] Banner ad entegrasyonu (free tier)
- [ ] Premium IAP entegrasyonu (lifetime)
- [ ] Onboarding (ilk açılış: dil + para birimi + ay başlangıcı)
- [ ] Beta testi → TestFlight + Firebase App Distribution
- [ ] **MVP Release v1.0.0**

### 16.2. Faz 2 — Cloud Sync (4 Sprint, 8 hafta)
- Sprint 9: Supabase setup + Auth + RLS policies
- Sprint 10: Sync engine (offline-first, last-write-wins)
- Sprint 11: Conflict resolution + Sync UI
- Sprint 12: Sync abonelik (recurring IAP), Polish, Release v1.5

### 16.3. Faz 3 — İleri Özellikler (6 Sprint, 12 hafta)
- Banka entegrasyonu (BKM/açık bankacılık) — TR pazarı için
- OCR ile fiş okuma (Google ML Kit)
- Aile/grup paylaşımı
- Web/PWA arayüzü
- iCloud + Google Drive yedekleme

### 16.4. Faz 4 — AI ve Genişleme (sürekli)
- AI kategori önerisi (TF Lite veya server-side)
- Yatırım/kripto takibi
- Apple Watch + Wear OS
- Sesli komut entegrasyonu

---

## 17. RISK VE ÖNLEMLERİ

| Risk | Etki | Olasılık | Önlem |
|---|---|---|---|
| Flutter performans (büyük listeler) | Y | O | `ListView.builder` + pagination + index'ler |
| iOS Sign-In ile Apple zorunlu | Y | Y | Faz 2'den itibaren mutlaka Apple Sign-In ekle |
| Drift migration hatası prod'da | Ç.Y | D | Migration dry-run test, snapshot DB ile rollback |
| Supabase bağımlılığı (vendor lock) | O | O | Repository pattern → backend swap edilebilir |
| App Store review reddi (finance kategorisi sıkı) | Y | O | Privacy manifest tam, banka olmadığını net belirt |
| Türkçe karakter encoding sorunları | O | O | UTF-8, intl, Drift collation dikkat |
| FX rate sapması | O | Y | Manuel override + güvenilir API (Frankfurter, exchangerate.host) |

---

## 18. EK NOTLAR VE KAYNAKLAR

### 18.1. Referans Linkleri
- Flutter: https://docs.flutter.dev
- Riverpod: https://riverpod.dev
- Drift: https://drift.simonbinder.eu
- go_router: https://pub.dev/packages/go_router
- Supabase Flutter: https://supabase.com/docs/reference/dart
- fl_chart: https://github.com/imaNNeo/fl_chart

### 18.2. Önerilen Lint Kuralları
`analysis_options.yaml`:
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    - prefer_single_quotes
    - require_trailing_commas
    - avoid_print
    - prefer_const_constructors
    - sort_pub_dependencies
```

### 18.3. Git Commit Convention
Conventional Commits:
```
feat: AddTransactionScreen formu eklendi
fix: Transfer'de bakiye hesabı düzeltildi
docs: SPEC bölüm 9.2 güncellendi
refactor: AccountRepository → AccountDao'ya bağlandı
test: TransactionForm provider testleri eklendi
chore: pubspec.yaml dependency güncellendi
```

### 18.4. Klonlamada Hukuki Notlar
- Realbyte'ın UI'ından ilham al, ama birebir kopyalama (özellikle ikonlar, brand renk)
- Kendi marka adı, logo, ikon, slogan yarat
- Privacy Policy ve Terms of Use kendi versiyonun
- Patent/trade dress ihlalinden kaçın → bir hukuk danışmanına danış (özellikle TR pazar lansmanı öncesi)

---

**Doküman Sonu — TOPLAM: 18 BÖLÜM**

Bu doküman Claude Code agent'ları tarafından parça parça okunup uygulanabilir şekilde tasarlanmıştır. Her bölüm referans olarak kullanılabilir.

Versiyon takibi için `CHANGELOG.md` tutulmalıdır.

