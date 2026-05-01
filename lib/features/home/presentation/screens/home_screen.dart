// HomeScreen placeholder for the Home tab — home feature.
// Real content is implemented in EPIC8A-03 and subsequent Phase 2 stories.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors_ext.dart';

/// Placeholder scaffold shown on the Home tab.
/// All content implementation is deferred to EPIC8A-03+.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Center(
        child: Text(
          'Home — coming soon',
          style: AppTypography.body.copyWith(color: context.textSecondary),
        ),
      ),
    );
  }
}
