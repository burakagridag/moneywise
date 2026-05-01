// Greeting header widget for the Home tab — home feature (EPIC8A-05).
// Displays a time-of-day greeting, locale-aware date, and a user avatar.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';

/// Presentational widget that greets the user by time of day.
///
/// Displays:
/// - A locale-aware date string (e.g. "Thursday, 30 April")
/// - A time-of-day greeting (Good morning / Good afternoon / Good evening)
///   optionally suffixed with ", {userName}" when [userName] is non-empty
/// - A 36 dp avatar circle showing the first letter of [userName] or a
///   generic person icon when [userName] is empty
///
/// This widget is purely presentational. It receives all data via
/// constructor parameters; no providers or async calls are made internally.
/// [currentDate] must be injected — the widget never calls [DateTime.now()].
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.userName = '',
    required this.currentDate,
    this.onAvatarTap,
  });

  /// Display name of the current user. May be empty or null-equivalent.
  final String userName;

  /// The date to display and derive the time-of-day greeting from.
  final DateTime currentDate;

  /// Callback fired when the avatar circle is tapped.
  /// Typically wires to `context.go(Routes.more)` in [HomeScreen].
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toString();

    final dateColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final greetingColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final avatarBg =
        isDark ? AppColors.bgSecondary : AppColors.bgSecondaryLight;
    final avatarBorder = isDark ? AppColors.border : AppColors.borderLight;
    final avatarTextColor =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    final dateString = _formatDate(currentDate, localeTag);
    final greetingString = _buildGreeting(l10n, currentDate.hour, userName);
    final trimmedName = userName.trim();
    final avatarInitial =
        trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: date + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateString,
                  style: AppTypography.caption1.copyWith(color: dateColor),
                  textScaler: TextScaler.linear(
                    _clampTextScale(MediaQuery.textScalerOf(context).scale(1)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  greetingString,
                  style: AppTypography.headline.copyWith(color: greetingColor),
                  textScaler: TextScaler.linear(
                    _clampTextScale(MediaQuery.textScalerOf(context).scale(1)),
                  ),
                ),
              ],
            ),
          ),
          // Right column: avatar with minimum 44 dp tap target
          Semantics(
            label: trimmedName.isNotEmpty
                ? 'Profile, $trimmedName. Tap to open settings.'
                : 'Profile. Tap to open settings.',
            button: true,
            child: GestureDetector(
              onTap: onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: _Avatar(
                    initial: avatarInitial,
                    backgroundColor: avatarBg,
                    borderColor: avatarBorder,
                    textColor: avatarTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a time-of-day greeting string, optionally appending the user name.
  ///
  /// Time ranges:
  ///   05:00–11:59 → Good morning
  ///   12:00–17:59 → Good afternoon
  ///   18:00–04:59 → Good evening
  static String _buildGreeting(
      AppLocalizations l10n, int hour, String userName) {
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = l10n.homeGreetingMorning;
    } else if (hour >= 12 && hour < 18) {
      greeting = l10n.homeGreetingAfternoon;
    } else {
      greeting = l10n.homeGreetingEvening;
    }

    final trimmed = userName.trim();
    if (trimmed.isNotEmpty) {
      return '$greeting, $trimmed';
    }
    return greeting;
  }

  /// Formats [date] locale-aware.
  ///
  /// EN: "Thursday, 30 April"
  /// TR: "30 Nisan Perşembe"
  static String _formatDate(DateTime date, String localeTag) {
    final isEn = localeTag.startsWith('en');
    final pattern = isEn ? 'EEEE, d MMMM' : 'd MMMM EEEE';
    return DateFormat(pattern, localeTag).format(date);
  }

  /// Clamps the text scale factor to the range [0.85, 1.3] per UX spec.
  static double _clampTextScale(double scale) => scale.clamp(0.85, 1.3);
}

// ---------------------------------------------------------------------------
// Private avatar sub-widget
// ---------------------------------------------------------------------------

/// 36 dp circular avatar showing a single initial or a person icon.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String? initial;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1,
              ),
            )
          : Icon(
              Icons.person_outline,
              size: 18,
              color: textColor,
            ),
    );
  }
}
