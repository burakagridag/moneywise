// BudgetPulseCard widget showing monthly budget health at a glance — home feature.
// Consumes effectiveBudgetProvider (ADR-010) and the monthly expense total.
// Three states: no-budget CTA, normal, over-budget. See spec.md and redlines.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../more/presentation/providers/app_preferences_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/user_settings_providers.dart';

// ---------------------------------------------------------------------------
// Internal dimension constants (per redlines.md — no AppSpacing token for 14dp)
// ---------------------------------------------------------------------------

const double _kCardPadding = 14.0;
const double _kHeaderToRemainingGap = 12.0;
const double _kRemainingToProgressGap = 10.0;
const double _kProgressToPaceGap = 10.0;
const double _kRemainingNumberToSubtextGap = 6.0;
const double _kProgressBarHeight = 6.0;
const double _kProgressBarRadius = 3.0;
const double _kTodayMarkerWidth = 1.5;
const double _kTodayMarkerHeight = 12.0;
const double _kCtaBodyGap = 4.0;
const double _kCtaButtonGap = 12.0;

/// Budget pulse card displayed on the Home tab.
///
/// Renders one of three states depending on data from [effectiveBudgetProvider]
/// and the current month's expense total:
///   1. **Loading** — shimmer skeleton.
///   2. **No budget** — CTA prompting the user to navigate to the Budget tab.
///   3. **Budget set** — remaining amount, progress bar with today-marker,
///      daily pace line. Over-budget variant uses expense color overrides.
class BudgetPulseCard extends ConsumerWidget {
  const BudgetPulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    final budgetAsync = ref.watch(effectiveBudgetProvider(month));
    final spentAsync = ref.watch(transactionsByMonthProvider);
    final prefsAsync = ref.watch(appPreferencesNotifierProvider);

    final currencySymbol = prefsAsync.maybeWhen(
      data: (p) => p.currencyCode == 'EUR' ? '€' : p.currencyCode,
      orElse: () => '€',
    );
    final locale = prefsAsync.maybeWhen(
      data: (p) => p.languageCode == 'tr' ? 'tr_TR' : 'en_US',
      orElse: () => 'tr_TR',
    );

    // Compute spent total from the transactions stream (sum of expense type).
    final double spent = spentAsync.maybeWhen(
      data: (txList) => txList
          .where((t) => t.type == 'expense' && !t.isExcluded && !t.isDeleted)
          .fold<double>(0.0, (sum, t) => sum + t.amount),
      orElse: () => 0.0,
    );

    return budgetAsync.when(
      loading: () => _BudgetPulseShimmer(),
      error: (_, __) => _BudgetPulseError(context: context),
      data: (budget) {
        if (budget == null || budget == 0.0) {
          return _BudgetPulseCta(context: context);
        }
        return _BudgetPulseContent(
          budget: budget,
          spent: spent,
          currencySymbol: currencySymbol,
          locale: locale,
          now: now,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card shell (shared container shape & shadow)
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Semantics(
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight,
            width: 1.0,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(_kCardPadding),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State 1: Loading shimmer
// ---------------------------------------------------------------------------

class _BudgetPulseShimmer extends StatefulWidget {
  @override
  State<_BudgetPulseShimmer> createState() => _BudgetPulseShimmerState();
}

class _BudgetPulseShimmerState extends State<_BudgetPulseShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final isDark = context.isDark;
          final baseColor =
              isDark ? AppColors.bgTertiary : AppColors.bgTertiaryLight;
          final highlightColor =
              isDark ? AppColors.bgSecondary : AppColors.bgSecondaryLight;
          final gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [baseColor, highlightColor, baseColor],
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBar(width: 80, height: 14, gradient: gradient),
                  _shimmerBar(width: 36, height: 12, gradient: gradient),
                ],
              ),
              const SizedBox(height: _kHeaderToRemainingGap),
              // Remaining row shimmer
              Row(
                children: [
                  _shimmerBar(width: 140, height: 18, gradient: gradient),
                  const SizedBox(width: _kRemainingNumberToSubtextGap),
                  _shimmerBar(width: 100, height: 12, gradient: gradient),
                ],
              ),
              const SizedBox(height: _kRemainingToProgressGap),
              // Progress bar shimmer
              SizedBox(
                height: _kProgressBarHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(_kProgressBarRadius),
                  ),
                ),
              ),
              const SizedBox(height: _kProgressToPaceGap),
              // Pace line shimmer
              _shimmerBar(width: 200, height: 10, gradient: gradient),
            ],
          );
        },
      ),
    );
  }

  Widget _shimmerBar({
    required double width,
    required double height,
    required LinearGradient gradient,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State 2: Error
// ---------------------------------------------------------------------------

class _BudgetPulseError extends StatelessWidget {
  const _BudgetPulseError({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    return _CardShell(
      child: SizedBox(
        height: 60,
        child: Center(
          child: Text(
            l10n.homeBudgetPulseUnavailable,
            style: AppTypography.caption1.copyWith(color: ctx.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State 3: No budget CTA
// ---------------------------------------------------------------------------

class _BudgetPulseCta extends StatelessWidget {
  const _BudgetPulseCta({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    final isDark = ctx.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Semantics(
      label: l10n.homeBudgetPulseSetCta,
      button: false,
      child: _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title only, no "View" link in CTA state
            Text(
              l10n.homeBudgetPulseTitle,
              style: AppTypography.bodyMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: _kHeaderToRemainingGap),
            Text(
              l10n.homeBudgetPulseSetCta,
              style: AppTypography.bodyMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: _kCtaBodyGap),
            Text(
              l10n.homeBudgetPulseSetCtaSubtitle,
              style: AppTypography.caption1.copyWith(color: textSecondary),
            ),
            const SizedBox(height: _kCtaButtonGap),
            Semantics(
              label: l10n.homeBudgetPulseSetCta,
              button: true,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.brandPrimary,
                ),
                onPressed: () => ctx.go(Routes.budget),
                child: Text(
                  l10n.homeBudgetPulseSetBudgetButton,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State 4: Budget set (normal or over-budget)
// ---------------------------------------------------------------------------

class _BudgetPulseContent extends StatelessWidget {
  const _BudgetPulseContent({
    required this.budget,
    required this.spent,
    required this.currencySymbol,
    required this.locale,
    required this.now,
  });

  final double budget;
  final double spent;
  final String currencySymbol;
  final String locale;
  final DateTime now;

  // ---------------------------------------------------------------------------
  // Business logic
  // ---------------------------------------------------------------------------

  double get _remaining => budget - spent;

  double get _fillFraction =>
      budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

  double get _markerFraction {
    final days = _daysInMonth;
    return days > 0 ? (_currentDay / days).clamp(0.0, 1.0) : 0.0;
  }

  int get _currentDay => now.day.clamp(1, _daysInMonth);

  int get _daysInMonth => DateTime(now.year, now.month + 1, 0).day;

  double get _actualDailyPace => _currentDay > 0 ? spent / _currentDay : 0.0;

  double get _safeDailyAmount {
    final remainingDays =
        (_daysInMonth - _currentDay + 1).clamp(1, _daysInMonth);
    return _remaining > 0 ? _remaining / remainingDays : 0.0;
  }

  bool get _isOverBudget => _remaining <= 0;

  bool get _isWarning =>
      !_isOverBudget &&
      _currentDay > 5 &&
      _safeDailyAmount > 0 &&
      _actualDailyPace > _safeDailyAmount * 1.5;

  // ---------------------------------------------------------------------------
  // Semantic label
  // ---------------------------------------------------------------------------

  String _buildSemanticLabel(
    AppLocalizations l10n,
    String formattedRemaining,
    String formattedBudget,
    String formattedPace,
    String formattedSafe,
  ) {
    if (_isOverBudget) {
      return '${l10n.homeBudgetPulseTitle}. '
          '${l10n.homeBudgetPulseOverBudget}. '
          '${l10n.homeBudgetPulseDailyPace}$formattedPace.';
    }
    return '${l10n.homeBudgetPulseTitle}. '
        '$formattedRemaining ${l10n.homeBudgetPulseLeftOf(formattedBudget)}. '
        '${l10n.homeBudgetPulseDailyPace}$formattedPace. '
        '${l10n.homeBudgetPulseCanSpend}$formattedSafe${l10n.homeBudgetPulsePerDay}.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final expenseColor = isDark ? AppColors.expenseDark : AppColors.expense;
    final todayMarkerColor =
        isDark ? AppColors.textTertiary : AppColors.textSecondaryLight;
    final progressBg =
        isDark ? AppColors.bgTertiary : AppColors.bgTertiaryLight;
    final fillColor = _isOverBudget ? expenseColor : AppColors.brandPrimary;

    final remainingColor = _isOverBudget ? expenseColor : textPrimary;

    final formattedRemaining = CurrencyFormatter.format(
      _remaining.abs(),
      symbol: currencySymbol,
      locale: locale,
    );
    final formattedBudget = CurrencyFormatter.format(
      budget,
      symbol: currencySymbol,
      locale: locale,
    );
    final formattedPace = CurrencyFormatter.format(
      _actualDailyPace,
      symbol: currencySymbol,
      locale: locale,
    );
    final formattedSafe = _safeDailyAmount > 0
        ? CurrencyFormatter.format(
            _safeDailyAmount,
            symbol: currencySymbol,
            locale: locale,
          )
        : null;

    final semanticLabel = _buildSemanticLabel(
      l10n,
      formattedRemaining,
      formattedBudget,
      formattedPace,
      formattedSafe ?? l10n.homeBudgetPulseOverBudget,
    );

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeBudgetPulseTitle,
                    style:
                        AppTypography.bodyMedium.copyWith(color: textPrimary),
                  ),
                  Semantics(
                    label: l10n.homeBudgetPulseViewSemanticLabel,
                    button: true,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => context.go(Routes.budget),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          '${l10n.homeBudgetPulseViewLink} →',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _kHeaderToRemainingGap),

              // --- Remaining amount row ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _isOverBudget ? '−$formattedRemaining' : formattedRemaining,
                    style: AppTypography.moneyMedium.copyWith(
                      color: remainingColor,
                    ),
                  ),
                  const SizedBox(width: _kRemainingNumberToSubtextGap),
                  Flexible(
                    child: Text(
                      l10n.homeBudgetPulseLeftOf(formattedBudget),
                      style: AppTypography.caption1.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _kRemainingToProgressGap),

              // --- Progress bar with today marker ---
              _BudgetProgressBar(
                fillFraction: _fillFraction,
                markerFraction: _markerFraction,
                fillColor: fillColor,
                backgroundCol: progressBg,
                markerColor: todayMarkerColor,
              ),
              const SizedBox(height: _kProgressToPaceGap),

              // --- Daily pace line ---
              _PaceLine(
                l10n: l10n,
                formattedPace: formattedPace,
                formattedSafe: formattedSafe,
                isOverBudget: _isOverBudget,
                isWarning: _isWarning,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar sub-widget (extracted per spec)
// ---------------------------------------------------------------------------

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({
    required this.fillFraction,
    required this.markerFraction,
    required this.fillColor,
    required this.backgroundCol,
    required this.markerColor,
  });

  final double fillFraction;
  final double markerFraction;
  final Color fillColor;
  final Color backgroundCol;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final markerLeft = (markerFraction * totalWidth)
              .clamp(0.0, totalWidth - _kTodayMarkerWidth);

          return SizedBox(
            height: _kTodayMarkerHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background bar (vertically centered in the stack height)
                Positioned(
                  top: (_kTodayMarkerHeight - _kProgressBarHeight) / 2,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: _kProgressBarHeight,
                    decoration: BoxDecoration(
                      color: backgroundCol,
                      borderRadius: BorderRadius.circular(_kProgressBarRadius),
                    ),
                  ),
                ),
                // Fill bar — explicit pixel width from totalWidth * fillFraction
                Positioned(
                  top: (_kTodayMarkerHeight - _kProgressBarHeight) / 2,
                  left: 0,
                  child: Container(
                    width: (totalWidth * fillFraction).clamp(0.0, totalWidth),
                    height: _kProgressBarHeight,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(_kProgressBarRadius),
                    ),
                  ),
                ),
                // Today marker — top: 0 places the 12dp marker at the top of the
                // 12dp stack. The 6dp progress bar starts at top=3 (centered),
                // so the marker bleeds 3dp above and below the bar exactly.
                Positioned(
                  left: markerLeft,
                  top: 0,
                  child: Container(
                    width: _kTodayMarkerWidth,
                    height: _kTodayMarkerHeight,
                    color: markerColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pace line sub-widget
// ---------------------------------------------------------------------------

class _PaceLine extends StatelessWidget {
  const _PaceLine({
    required this.l10n,
    required this.formattedPace,
    required this.formattedSafe,
    required this.isOverBudget,
    required this.isWarning,
    required this.isDark,
  });

  final AppLocalizations l10n;
  final String formattedPace;
  final String? formattedSafe;
  final bool isOverBudget;
  final bool isWarning;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.caption2.copyWith(
      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
    );
    final paceNumberStyle = AppTypography.caption2.copyWith(
      fontWeight: FontWeight.w500,
      color: isWarning
          ? AppColors.warning
          : (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
    );
    final safeStyle = AppTypography.caption2.copyWith(
      fontWeight: FontWeight.w600,
      color: isOverBudget
          ? (isDark ? AppColors.expenseDark : AppColors.expense)
          : AppColors.success,
    );

    final List<InlineSpan> spans = [
      TextSpan(text: l10n.homeBudgetPulseDailyPace, style: baseStyle),
      TextSpan(text: formattedPace, style: paceNumberStyle),
    ];

    if (isOverBudget) {
      spans.add(
        TextSpan(text: l10n.homeBudgetPulseOverBudgetSuffix, style: safeStyle),
      );
    } else {
      spans
        ..add(TextSpan(text: l10n.homeBudgetPulseCanSpend, style: baseStyle))
        ..add(
          TextSpan(
            text: '${formattedSafe ?? "0"}${l10n.homeBudgetPulsePerDay}',
            style: safeStyle,
          ),
        );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
