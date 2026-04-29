// Data recovery screen — allows resetting all data when encryption key is lost — security feature.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../data/local/encryption/db_encryption_service.dart';

/// Shown when the app cannot decrypt the database (e.g. key deleted from Keychain).
/// Provides a single destructive action: delete the encryption key so the app
/// can create a new encrypted database from scratch.
class DataRecoveryScreen extends StatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  State<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends State<DataRecoveryScreen> {
  bool _isResetting = false;

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          'Reset All Data?',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete your encryption key and all local data. '
          'This action cannot be undone.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResetting = true);
    try {
      await DbEncryptionService.deleteKey();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encryption key deleted. Please restart the app.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          'Data Recovery',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              const Icon(
                Icons.warning_outlined,
                size: 72,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Database Unavailable',
                style:
                    AppTypography.title2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your data could not be decrypted. This may happen if the '
                'encryption key was removed from the device keychain.',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FilledButton(
                onPressed: _isResetting ? null : _resetAllData,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(AppHeights.button),
                ),
                child: _isResetting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text('Reset All Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
