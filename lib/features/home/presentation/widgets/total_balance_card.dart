// TotalBalanceCard widget — displays total balance, trend chip, and sparkline — home feature (EPIC8A-06).
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/local/daos/transaction_dao.dart';
import '../providers/net_worth_provider.dart';
import '../providers/sparkline_provider.dart';

/// Dark-mode gradient start colour — widget-local per redlines.md.
/// Not a named AppColors token; approved by Sponsor (spec.md §Visual Design).
const Color _darkGradientStart = Color(0xFF4F46E5);

/// Shimmer animation duration — 1200ms per tokens.json.
const Duration _shimmerDuration = Duration(milliseconds: 1200);

/// Sparkline draw-on animation duration — 300ms per tokens.json.
const Duration _sparklineDuration = Duration(milliseconds: 300);

/// Number of daily net data points rendered in the sparkline.
const int _sparklineDays = 30;

// ---------------------------------------------------------------------------
// File-scope style constants — used by both _ErrorContent and _CardContent
// to avoid duplication between error and data states.
// ---------------------------------------------------------------------------

/// Label style for the "TOTAL BALANCE" caption — shared across error and data states.
final TextStyle _kLabelStyle = AppTypography.caption2.copyWith(
  color: Colors.white.withValues(alpha: 0.70),
  letterSpacing: 0.5,
);

/// Balance value style — shared across error and data states.
final TextStyle _kBalanceStyle = AppTypography.moneyLarge.copyWith(
  fontSize: 30,
  fontWeight: FontWeight.w600,
  color: AppColors.textOnBrand,
);

/// The primary Home tab card, displaying total balance across all included
/// accounts, a trend chip comparing to the previous month, and a 30-day
/// sparkline chart.
///
/// States:
///   - loading → shimmer bars on gradient background
///   - error   → "— €" balance, no trend chip, no sparkline
///   - data    → full content with optional trend chip
///
/// V2 note: [accounts] prop accepted but sub-card UI not rendered.
class TotalBalanceCard extends ConsumerWidget {
  const TotalBalanceCard({super.key, this.accounts = const []});

  /// Reserved for V2 account sub-card UI. Silently ignored in V1.
  final List<Object> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountsTotalProvider);
    final previousAsync = ref.watch(previousMonthTotalProvider);
    final sparklineAsync = ref.watch(sparklineDataProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final balance = balanceAsync.valueOrNull;
    final previousBalance = previousAsync.valueOrNull;

    // Build semantic label for accessibility.
    final semanticLabel = _buildSemanticLabel(
      balance: balance,
      previousBalance: previousBalance,
      l10n: l10n,
    );

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [_darkGradientStart, AppColors.brandPrimary]
                  : [AppColors.brandPrimary, AppColors.brandPrimaryDim],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: balanceAsync.when(
            loading: () => const _ShimmerContent(),
            error: (_, __) => const _ErrorContent(),
            data: (_) => _CardContent(
              balance: balance ?? 0.0,
              previousBalance: previousBalance,
              sparklineAsync: sparklineAsync,
            ),
          ),
        ),
      ),
    );
  }

  static String _buildSemanticLabel({
    required double? balance,
    required double? previousBalance,
    required AppLocalizations l10n,
  }) {
    final formattedBalance =
        balance != null ? CurrencyFormatter.format(balance) : '— €';

    final showTrend = previousBalance != null && previousBalance != 0.0;
    if (!showTrend || balance == null) {
      return 'Total balance: $formattedBalance.';
    }

    final delta = balance - previousBalance;
    final direction = delta >= 0 ? 'Up' : 'Down';
    final formattedDelta = CurrencyFormatter.format(delta.abs());
    return 'Total balance: $formattedBalance. $direction $formattedDelta since last month.';
  }
}

// ---------------------------------------------------------------------------
// Loading state — shimmer bars on gradient background
// ---------------------------------------------------------------------------

class _ShimmerContent extends StatefulWidget {
  const _ShimmerContent();

  @override
  State<_ShimmerContent> createState() => _ShimmerContentState();
}

class _ShimmerContentState extends State<_ShimmerContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _shimmerDuration,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBar(width: 80, height: 10, shimmerValue: _shimmer.value),
            const SizedBox(height: 6),
            _ShimmerBar(width: 180, height: 28, shimmerValue: _shimmer.value),
            const SizedBox(height: 8),
            _ShimmerBar(width: 120, height: 14, shimmerValue: _shimmer.value),
            const SizedBox(height: 12),
            _ShimmerBar(
              width: double.infinity,
              height: 36,
              shimmerValue: _shimmer.value,
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.shimmerValue,
  });

  final double width;
  final double height;
  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        gradient: LinearGradient(
          begin: Alignment(shimmerValue - 1, 0),
          end: Alignment(shimmerValue, 0),
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorContent extends StatelessWidget {
  const _ErrorContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOTAL BALANCE', style: _kLabelStyle),
        const SizedBox(height: 6),
        Text('— €', style: _kBalanceStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data state — full content
// ---------------------------------------------------------------------------

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.balance,
    required this.previousBalance,
    required this.sparklineAsync,
  });

  final double balance;
  final double? previousBalance;
  final AsyncValue<List<DailyNet>> sparklineAsync;

  bool get _showTrend => previousBalance != null && previousBalance != 0.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Text(l10n.homeTotalBalanceLabel.toUpperCase(), style: _kLabelStyle),
        const SizedBox(height: 6),

        // Balance value
        Text(CurrencyFormatter.format(balance), style: _kBalanceStyle),
        const SizedBox(height: 8),

        // Trend row (hidden when previousBalance is null or zero)
        if (_showTrend) ...[
          _TrendRow(
            balance: balance,
            previousBalance: previousBalance!,
            l10n: l10n,
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 12),

        // Sparkline
        SizedBox(
          height: 36,
          child: ExcludeSemantics(
            child: sparklineAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => _Sparkline(data: data),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chip + label row
// ---------------------------------------------------------------------------

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.balance,
    required this.previousBalance,
    required this.l10n,
  });

  final double balance;
  final double previousBalance;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final delta = balance - previousBalance;
    final arrowChar = delta >= 0 ? '↑' : '↓';
    final formattedDelta = CurrencyFormatter.format(delta.abs());
    final chipText = '$arrowChar $formattedDelta';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trend chip — intrinsic width only.
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            chipText,
            style: AppTypography.caption2.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textOnBrand,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Trend label — allow shrinking on narrow screens.
        Flexible(
          child: Text(
            l10n.homeTrendSinceLastMonth,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption1.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkline — fl_chart LineChart with draw-on animation
// ---------------------------------------------------------------------------

class _Sparkline extends StatefulWidget {
  const _Sparkline({required this.data});

  final List<DailyNet> data;

  @override
  State<_Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<_Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  /// True when data is effectively flat (all zero or single point).
  /// Uses epsilon comparison to avoid floating-point equality issues.
  bool get _isFlat {
    if (widget.data.length < 2) return true;
    final first = widget.data.first.netAmount;
    return widget.data.every((d) => (d.netAmount - first).abs() < 0.001);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _sparklineDuration,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Only animate on first paint when data has meaningful variation.
    if (!_isFlat) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the full list of spots using index as x-axis (per ADR-012).
  List<FlSpot> _buildAllSpots() {
    if (widget.data.isEmpty) {
      return [const FlSpot(0, 0), const FlSpot(_sparklineDays - 1.0, 0)];
    }
    return widget.data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netAmount))
        .toList();
  }

  /// Clips the full spots list to those with x <= [visibleMaxX].
  /// Always includes at least the origin point for a valid chart.
  List<FlSpot> _clippedSpots(List<FlSpot> all, double visibleMaxX) {
    final visible = all.where((s) => s.x <= visibleMaxX).toList();
    if (visible.isEmpty) return [FlSpot(0, all.isNotEmpty ? all.first.y : 0)];
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final allSpots = _buildAllSpots();
    final fullMaxX = allSpots.last.x;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final visibleMaxX = _isFlat ? fullMaxX : fullMaxX * _progress.value;
        final spots = _clippedSpots(allSpots, visibleMaxX);

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: fullMaxX,
            clipData: const FlClipData.all(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _isFlat
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.50),
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _isFlat
                        ? [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.00),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.00),
                          ],
                  ),
                ),
              ),
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
          ),
          duration: Duration.zero,
        );
      },
    );
  }
}
