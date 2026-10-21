import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/url_opener.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'legal_repository.dart';

final legalDocsProvider = FutureProvider.autoDispose<LegalDocs>(
  (ref) => ref.watch(legalRepositoryProvider).current(),
  retry: (_, _) => null,
);

/// The current documents; a previous failure is retried.
Future<LegalDocs> loadLegalDocs(WidgetRef ref) {
  if (ref.read(legalDocsProvider).hasError) ref.invalidate(legalDocsProvider);
  return ref.read(legalDocsProvider.future);
}

/// "Terms of Service" and "Privacy Policy" links, opened in the browser.
class LegalLinks extends ConsumerWidget {
  const LegalLinks({super.key, this.keyPrefix = 'legal'});

  final String keyPrefix;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    String Function(LegalDocs d) url,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void say(String m) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(key: Key('$keyPrefix.linkError'), content: Text(m)),
      );
    final LegalDocs docs;
    try {
      docs = await loadLegalDocs(ref);
    } catch (_) {
      say(l.legalLoadFailed);
      return;
    }
    if (!await ref.read(urlOpenerProvider).open(url(docs))) {
      say(l.linkOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Prefetch so the links and the accepted versions are ready.
    ref.watch(legalDocsProvider);
    return Wrap(
      spacing: AppSpacing.s2,
      children: [
        TextButton.icon(
          key: Key('$keyPrefix.terms'),
          onPressed: () => _open(context, ref, (d) => d.terms.url),
          icon: const Icon(Icons.open_in_new, size: AppSpacing.s4),
          label: Text(l.legalTermsLink),
        ),
        TextButton.icon(
          key: Key('$keyPrefix.privacy'),
          onPressed: () => _open(context, ref, (d) => d.privacy.url),
          icon: const Icon(Icons.open_in_new, size: AppSpacing.s4),
          label: Text(l.legalPrivacyLink),
        ),
      ],
    );
  }
}

/// "I agree to the Terms of Service and Privacy Policy" checkbox with both links.
class LegalConsent extends StatelessWidget {
  const LegalConsent({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.keyPrefix = 'legal',
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: Key('$keyPrefix.agree'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
            ),
            child: Row(
              children: [
                Checkbox(
                  key: Key('$keyPrefix.checkbox'),
                  value: value,
                  activeColor: c.brand500,
                  checkColor: c.inkOnBrand,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onChanged: (v) => onChanged(v ?? false),
                ),
                const SizedBox(width: AppSpacing.s1),
                Expanded(
                  child: Text(
                    l.legalAgreeLabel,
                    style: AppTextStyles.bodySm.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        LegalLinks(keyPrefix: keyPrefix),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Text(
              errorText!,
              key: Key('$keyPrefix.error'),
              style: AppTextStyles.bodySm.copyWith(color: c.statusError),
            ),
          ),
      ],
    );
  }
}
