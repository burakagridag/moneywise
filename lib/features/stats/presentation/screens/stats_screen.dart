// Placeholder screen for the Stats tab (Sprint 1 scaffold).
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_typography.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Stats',
          style: AppTypography.title2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
