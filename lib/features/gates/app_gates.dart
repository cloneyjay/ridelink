import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/url_opener.dart';
import '../../core/version/version_gate.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../legal/legal_repository.dart';
import '../legal/terms_update_screen.dart';

/// Blocking screens above the whole app: "Update required" first, then "We've updated our
/// terms" (signed in only). Otherwise the app itself.
class AppGates extends ConsumerWidget {
  const AppGates({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(versionGateProvider);
    if (version is UpdateRequired) {
      return UpdateRequiredScreen(storeUrl: version.storeUrl);
    }
    if (ref.watch(legalUpdateRequiredProvider).value ?? false) {
      return const TermsUpdateScreen();
    }
    return child;
  }
}

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key, this.storeUrl});

  final String? storeUrl;

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final url = storeUrl;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    if (url != null && await ref.read(urlOpenerProvider).open(url)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('update.openFailed'),
          content: Text(l.linkOpenFailed),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.updateRequired'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.system_update,
                  size: AppSpacing.s12,
                  color: c.brand500,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  l.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMd.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l.updateRequiredBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpacing.s6),
                PrimaryButton(
                  key: const Key('update.open'),
                  label: l.updateRequiredButton,
                  onPressed: () => _openStore(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
