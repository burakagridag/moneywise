// Placeholder screen for the Accounts tab (Sprint 1 scaffold).
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_typography.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Accounts',
          style: AppTypography.title2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
