import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Foundation-only screen body: the app name, optionally with a progress indicator.
class BrandPlaceholder extends StatelessWidget {
  const BrandPlaceholder({super.key, this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).appName,
                  style: AppTextStyles.displayXl.copyWith(
                    color: context.colors.ink,
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: AppSpacing.s6),
                  CircularProgressIndicator(color: context.colors.brand500),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
