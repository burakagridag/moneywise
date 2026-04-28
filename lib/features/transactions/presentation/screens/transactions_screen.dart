// Placeholder screen for the Transactions tab (Sprint 1 scaffold).
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_typography.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Transactions',
          style: AppTypography.title2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
