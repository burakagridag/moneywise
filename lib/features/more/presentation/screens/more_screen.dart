// Placeholder screen for the More tab (Sprint 1 scaffold).
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_typography.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'More',
          style: AppTypography.title2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
