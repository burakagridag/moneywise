// DEMO ONLY — Sponsor visual review screen. NOT production code. Delete after screenshots.
// Shows every Phase 2 HomeScreen component with hardcoded mock data.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/local/daos/transaction_dao.dart';
import '../../../../domain/entities/transaction_with_details.dart' as domain_details;
import '../../../../domain/entities/transaction.dart' as domain_tx;
import '../../../../features/insights/domain/insight.dart';
import '../../../../features/insights/presentation/providers/insights_providers.dart';
import '../../../../features/more/presentation/providers/app_preferences_provider.dart';
import '../../../../features/transactions/presentation/providers/transactions_provider.dart';
import '../providers/net_worth_provider.dart';
import '../providers/recent_transactions_provider.dart';
import '../providers/sparkline_provider.dart';
import '../providers/user_settings_providers.dart';
import '../widgets/budget_pulse_card.dart';
import '../widgets/home_header.dart';
import '../widgets/insight_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/total_balance_card.dart';

// ---------------------------------------------------------------------------
// Hardcoded mock data
// ---------------------------------------------------------------------------

final _mockSparklineData = List.generate(30, (i) {
  final values = [
    120.0,
    -45.0,
    80.0,
    0.0,
    200.0,
    -30.0,
    150.0,
    90.0,
    -20.0,
    60.0,
    110.0,
    -80.0,
    40.0,
    0.0,
    95.0,
    -15.0,
    180.0,
    30.0,
    -60.0,
    75.0,
    0.0,
    130.0,
    -25.0,
    85.0,
    40.0,
    -50.0,
    100.0,
    60.0,
    -35.0,
    90.0,
  ];
  return DailyNet(
    date: DateTime.now().subtract(Duration(days: 29 - i)),
    netAmount: values[i],
  );
});

final _mockTransactions = [
  Transaction(
    id: 'demo-1',
    type: 'income',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    amount: 3200.00,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    description: 'Monthly Salary',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: 'demo-2',
    type: 'expense',
    date: DateTime.now().subtract(const Duration(hours: 5)),
    amount: 47.50,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    description: 'Grocery Shopping',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: 'demo-3',
    type: 'expense',
    date: DateTime.now().subtract(const Duration(days: 1)),
    amount: 12.90,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    description: 'Coffee & Lunch',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: 'demo-4',
    type: 'transfer',
    date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    amount: 500.00,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    toAccountId: 'acc-2',
    description: 'Savings Transfer',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: 'demo-5',
    type: 'expense',
    date: DateTime.now().subtract(const Duration(days: 2)),
    amount: 89.99,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    description: 'Electricity Bill',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

/// Mock transactions wrapped in [TransactionWithDetails] for the
/// [recentTransactionsProvider] override (which now emits
/// `List<TransactionWithDetails>` after the display-name fix).
final _mockTransactionDetails = _mockTransactions.map((tx) {
  final domainTx = domain_tx.Transaction(
    id: tx.id,
    type: tx.type,
    date: tx.date,
    amount: tx.amount,
    currencyCode: tx.currencyCode,
    accountId: tx.accountId,
    toAccountId: tx.toAccountId,
    description: tx.description,
    createdAt: tx.createdAt,
    updatedAt: tx.updatedAt,
  );
  return domain_details.TransactionWithDetails(
    transaction: domainTx,
    categoryName: switch (tx.type) {
      'income' => 'Salary',
      'expense' => 'Shopping',
      'transfer' => null,
      _ => null,
    },
  );
}).toList();

// ---------------------------------------------------------------------------
// Fake preferences notifier — avoids SharedPreferences I/O
// ---------------------------------------------------------------------------

class _FakePrefsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async => const AppPreferences(
        themeMode: ThemeMode.light,
        currencyCode: 'EUR',
        languageCode: 'en',
      );
}

// ---------------------------------------------------------------------------
// Provider overrides builders
// ---------------------------------------------------------------------------

List<Override> _balanceFilledOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    accountsTotalProvider.overrideWith((_) => Stream.value(12450.60)),
    previousMonthTotalProvider.overrideWith((_) async => 11800.0),
    sparklineDataProvider.overrideWith((_) => Stream.value(_mockSparklineData)),
    effectiveBudgetProvider(month).overrideWith((_) async => 2000.0),
    transactionsByMonthProvider.overrideWith(
      (_) => Stream.value(
          _mockTransactions.where((t) => t.type == 'expense').toList()),
    ),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider
        .overrideWith((_) => Stream.value(_mockTransactionDetails)),
  ];
}

List<Override> _balanceNegativeTrendOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    accountsTotalProvider.overrideWith((_) => Stream.value(9800.0)),
    previousMonthTotalProvider.overrideWith((_) async => 11200.0),
    sparklineDataProvider.overrideWith((_) => Stream.value(_mockSparklineData)),
    effectiveBudgetProvider(month).overrideWith((_) async => 2000.0),
    transactionsByMonthProvider
        .overrideWith((_) => Stream.value(_mockTransactions)),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider
        .overrideWith((_) => Stream.value(_mockTransactionDetails)),
  ];
}

List<Override> _balanceZeroOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    accountsTotalProvider.overrideWith((_) => Stream.value(0.0)),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => Stream.value(const [])),
    effectiveBudgetProvider(month).overrideWith((_) async => null),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(const [])),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider.overrideWith((_) => Stream.value(const [])),
  ];
}

List<Override> _budgetCtaOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    effectiveBudgetProvider(month).overrideWith((_) async => null),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(const [])),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider.overrideWith((_) => const Stream.empty()),
  ];
}

List<Override> _budgetWithinBudgetOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final expenseTxns = [
    Transaction(
      id: 'b-1',
      type: 'expense',
      date: DateTime.now(),
      amount: 800.0,
      currencyCode: 'EUR',
      accountId: 'acc-1',
      description: 'Various expenses',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  return [
    effectiveBudgetProvider(month).overrideWith((_) async => 2000.0),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(expenseTxns)),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider.overrideWith((_) => const Stream.empty()),
  ];
}

List<Override> _budgetOverBudgetOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final expenseTxns = [
    Transaction(
      id: 'b-2',
      type: 'expense',
      date: DateTime.now(),
      amount: 1800.0,
      currencyCode: 'EUR',
      accountId: 'acc-1',
      description: 'Overspent this month',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  return [
    effectiveBudgetProvider(month).overrideWith((_) async => 1500.0),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(expenseTxns)),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    insightsProvider.overrideWith((_) async => const []),
    recentTransactionsProvider.overrideWith((_) => const Stream.empty()),
  ];
}

List<Override> _recentFilledOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    recentTransactionsProvider
        .overrideWith((_) => Stream.value(_mockTransactionDetails)),
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    effectiveBudgetProvider(month).overrideWith((_) async => null),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(const [])),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    insightsProvider.overrideWith((_) async => const []),
  ];
}

List<Override> _recentEmptyOverrides() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  return [
    recentTransactionsProvider.overrideWith((_) => Stream.value(const [])),
    accountsTotalProvider.overrideWith((_) => const Stream.empty()),
    previousMonthTotalProvider.overrideWith((_) async => null),
    sparklineDataProvider.overrideWith((_) => const Stream.empty()),
    effectiveBudgetProvider(month).overrideWith((_) async => null),
    transactionsByMonthProvider.overrideWith((_) => Stream.value(const [])),
    appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    insightsProvider.overrideWith((_) async => const []),
  ];
}

// ---------------------------------------------------------------------------
// Mock insights
// ---------------------------------------------------------------------------

const _concentrationInsight = Insight(
  id: 'concentration',
  severity: InsightSeverity.warning,
  headline: 'Spending concentration alert',
  body: 'Top category is 73% of your spending',
  icon: Icons.warning_amber_rounded,
  iconColor: Color(0xFFC2410C),
  iconBackgroundColor: Color(0x26FFA726),
);

const _savingsGoalInsight = Insight(
  id: 'savings_goal',
  severity: InsightSeverity.info,
  headline: 'On track for savings goal',
  body: "You're on track to save €400 this month",
  icon: Icons.savings_outlined,
  iconColor: Color(0xFF3D5A99),
  iconBackgroundColor: Color(0xFFD6DCF0),
);

// ---------------------------------------------------------------------------
// Main demo screen
// ---------------------------------------------------------------------------

/// DEMO ONLY — scrollable gallery of all Phase 2 Home tab component states.
/// Not production code. Delete after sponsor screenshots.
/// [showPage2] selects sections 5–12 (lower half of gallery).
class HomeDemoScreen extends StatefulWidget {
  const HomeDemoScreen({super.key, this.showPage2 = false});

  final bool showPage2;

  @override
  State<HomeDemoScreen> createState() => _HomeDemoScreenState();
}

class _HomeDemoScreenState extends State<HomeDemoScreen> {
  bool _isDark = false;

  // Fixed reference date: Thursday 1 May 2026 at 09:30
  static final _demoDate = DateTime(2026, 5, 1, 9, 30);

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? AppTheme.dark : AppTheme.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: _DemoGallery(
        isDark: _isDark,
        demoDate: _demoDate,
        showPage2: widget.showPage2,
        onToggleTheme: (v) => setState(() => _isDark = v),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery scaffold (built inside MaterialApp so l10n & theme are available)
// ---------------------------------------------------------------------------

class _DemoGallery extends StatelessWidget {
  const _DemoGallery({
    required this.isDark,
    required this.demoDate,
    required this.showPage2,
    required this.onToggleTheme,
  });

  final bool isDark;
  final DateTime demoDate;
  final bool showPage2;
  final ValueChanged<bool> onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.bgPrimary : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Phase 2 Demo Gallery',
          style: AppTypography.headline.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Switch(
                  value: isDark,
                  onChanged: onToggleTheme,
                  activeThumbColor: AppColors.brandPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: showPage2
              ? _page2Sections(isDark)
              : _page1Sections(isDark, demoDate),
        ),
      ),
    );
  }

  // ── Page 1: sections 1–4 (top half of gallery) ──────────────────────────

  List<Widget> _page1Sections(bool isDark, DateTime demoDate) => [
        _SectionLabel(
            label: '1 · HomeHeader — with name "Jane Doe"', isDark: isDark),
        _CardFrame(
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: HomeHeader(userName: 'Jane Doe', currentDate: demoDate),
          ),
        ),
        _SectionLabel(
            label: '2 · HomeHeader — guest (no name)', isDark: isDark),
        _CardFrame(
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: HomeHeader(userName: '', currentDate: demoDate),
          ),
        ),
        _SectionLabel(
            label: '3 · TotalBalanceCard — €12,450.60  (+€650.60 trend)',
            isDark: isDark),
        ProviderScope(
          overrides: _balanceFilledOverrides(),
          child: const TotalBalanceCard(),
        ),
        _SectionLabel(
            label: '4 · TotalBalanceCard — €9,800.00  (−€1,400 trend)',
            isDark: isDark),
        ProviderScope(
          overrides: _balanceNegativeTrendOverrides(),
          child: const TotalBalanceCard(),
        ),
        const SizedBox(height: AppSpacing.xl),
      ];

  // ── Page 2: sections 5–12 (lower half of gallery) ───────────────────────

  List<Widget> _page2Sections(bool isDark) => [
        _SectionLabel(
            label: '5 · TotalBalanceCard — €0.00 / no trend', isDark: isDark),
        ProviderScope(
          overrides: _balanceZeroOverrides(),
          child: const TotalBalanceCard(),
        ),
        _SectionLabel(
            label: '6 · BudgetPulseCard — CTA (no budget set)', isDark: isDark),
        _BudgetFrame(overrides: _budgetCtaOverrides(), isDark: isDark),
        _SectionLabel(
            label: '7 · BudgetPulseCard — within budget (€800 / €2,000)',
            isDark: isDark),
        _BudgetFrame(overrides: _budgetWithinBudgetOverrides(), isDark: isDark),
        _SectionLabel(
            label: '8 · BudgetPulseCard — over budget (€1,800 / €1,500)',
            isDark: isDark),
        _BudgetFrame(overrides: _budgetOverBudgetOverrides(), isDark: isDark),
        _SectionLabel(
            label: '9 · InsightCard — warning severity', isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 4),
          child: InsightCard(
            icon: _concentrationInsight.icon,
            iconColor: _concentrationInsight.iconColor,
            iconBackgroundColor: _concentrationInsight.iconBackgroundColor,
            title: _concentrationInsight.headline,
            subtitle: _concentrationInsight.body,
          ),
        ),
        _SectionLabel(
            label: '10 · InsightCard — info severity', isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 4),
          child: InsightCard(
            icon: _savingsGoalInsight.icon,
            iconColor: _savingsGoalInsight.iconColor,
            iconBackgroundColor: _savingsGoalInsight.iconBackgroundColor,
            title: _savingsGoalInsight.headline,
            subtitle: _savingsGoalInsight.body,
          ),
        ),
        _SectionLabel(
            label:
                '11 · RecentTransactionsList — 5 transactions (renders top 2)',
            isDark: isDark),
        ProviderScope(
          overrides: _recentFilledOverrides(),
          child: RecentTransactionsList(onSeeAllTap: () {}),
        ),
        _SectionLabel(
            label: '12 · RecentTransactionsList — 0 transactions (hidden)',
            isDark: isDark),
        _CardFrame(
          isDark: isDark,
          child: Column(
            children: [
              ProviderScope(
                overrides: _recentEmptyOverrides(),
                child: RecentTransactionsList(onSeeAllTap: () {}),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Text(
                  '↑ Widget is SizedBox.shrink() — zero height above this label',
                  style: AppTypography.caption1.copyWith(
                    color: isDark
                        ? AppColors.textTertiary
                        : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ];
}

// ---------------------------------------------------------------------------
// BudgetPulseCard frame — needs a GoRouter context for the "View →" tap target
// ---------------------------------------------------------------------------

class _BudgetFrame extends StatelessWidget {
  const _BudgetFrame({required this.overrides, required this.isDark});

  final List<Override> overrides;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // BudgetPulseCard calls context.go() internally, so it needs a GoRouter.
    final router = GoRouter(
      initialLocation: '/demo',
      routes: [
        GoRoute(
          path: '/demo',
          builder: (_, __) => Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ProviderScope(
                overrides: overrides,
                child: const BudgetPulseCard(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/budget',
          builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );

    return SizedBox(
      height: 200,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: isDark ? AppTheme.dark : AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI helpers
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 6),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(
          color: isDark ? AppColors.brandPrimary : const Color(0xFF3D5A99),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}
