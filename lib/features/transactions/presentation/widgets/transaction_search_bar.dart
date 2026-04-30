// Animated search bar widget for the transactions list — transactions feature.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../providers/search_filter_provider.dart';

/// A debounced search bar that animates in below the AppBar.
/// Updates [SearchQueryNotifier] with a 300ms debounce.
class TransactionSearchBar extends ConsumerStatefulWidget {
  const TransactionSearchBar({super.key, required this.isVisible});

  /// Whether the search bar is currently visible.
  final bool isVisible;

  @override
  ConsumerState<TransactionSearchBar> createState() =>
      _TransactionSearchBarState();
}

class _TransactionSearchBarState extends ConsumerState<TransactionSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _heightAnimation;
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heightAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(TransactionSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animController.forward();
      } else {
        _animController.reverse().whenComplete(_clearSearch);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryNotifierProvider.notifier).clear();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryNotifierProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1,
      child: Container(
        color: AppColors.bgSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: _clearSearch,
                );
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.bgTertiary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }
}
