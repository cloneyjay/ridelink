import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Landing spot after "Join as a boda boda rider"; real rider screens come later.
class RiderOnboardingPlaceholderScreen extends ConsumerStatefulWidget {
  const RiderOnboardingPlaceholderScreen({super.key});

  @override
  ConsumerState<RiderOnboardingPlaceholderScreen> createState() =>
      _RiderOnboardingPlaceholderScreenState();
}

class _RiderOnboardingPlaceholderScreenState
    extends ConsumerState<RiderOnboardingPlaceholderScreen> {
  @override
  void initState() {
    super.initState();
    // The intent has done its job; clear after the frame so the router isn't notified mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(riderIntentProvider).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen.riderOnboarding'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            child: Text(
              AppLocalizations.of(context).riderOnboardingTitle,
              style: AppTextStyles.displayLg.copyWith(
                color: context.colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
