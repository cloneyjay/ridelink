import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import 'legal_repository.dart';
import 'legal_widgets.dart';

/// Blocking: the signed-in user must accept the updated Terms and Privacy Policy, or sign out.
class TermsUpdateScreen extends ConsumerStatefulWidget {
  const TermsUpdateScreen({super.key});

  @override
  ConsumerState<TermsUpdateScreen> createState() => _TermsUpdateScreenState();
}

class _TermsUpdateScreenState extends ConsumerState<TermsUpdateScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final docs = await loadLegalDocs(ref);
      await ref
          .read(legalRepositoryProvider)
          .accept(
            termsVersion: docs.terms.version,
            privacyVersion: docs.privacy.version,
          );
      ref.invalidate(legalUpdateRequiredProvider);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = apiErrorText(e, l, fallback: l.legalUpdateAcceptFailed),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.termsUpdate'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.s8),
            Icon(
              Icons.policy_outlined,
              size: AppSpacing.s12,
              color: c.brand500,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              l.legalUpdateTitle,
              style: AppTextStyles.displayMd.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              l.legalUpdateBody,
              style: AppTextStyles.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s4),
            const LegalLinks(keyPrefix: 'termsUpdate'),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s3),
              InlineError(_error!, key: const Key('termsUpdate.error')),
            ],
            const SizedBox(height: AppSpacing.s6),
            PrimaryButton(
              key: const Key('termsUpdate.accept'),
              label: l.legalUpdateAccept,
              loading: _busy,
              onPressed: _accept,
            ),
            const SizedBox(height: AppSpacing.s3),
            TextButton(
              key: const Key('termsUpdate.signOut'),
              onPressed: _busy
                  ? null
                  : () => ref.read(sessionManagerProvider).signOut(),
              child: Text(l.menuSignOut),
            ),
          ],
        ),
      ),
    );
  }
}
