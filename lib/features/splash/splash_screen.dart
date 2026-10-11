import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../common/brand_placeholder.dart';

/// Startup screen; when the stored session can't be checked offline, offers Retry.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(sessionManagerProvider).retry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(sessionStateProvider) is SessionOffline;
    if (!offline) {
      return const BrandPlaceholder(
        key: Key('screen.splash'),
        showProgress: true,
      );
    }

    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.splash'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            child: Column(
              key: const Key('splash.offline'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, color: c.inkMuted),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  l.offlineTitle,
                  style: AppTextStyles.displayMd.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l.offlineBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpacing.s6),
                ElevatedButton(
                  key: const Key('splash.retry'),
                  onPressed: _retrying ? null : _retry,
                  child: Text(l.retryButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
