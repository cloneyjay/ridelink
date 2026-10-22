import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../auth/auth_notice.dart';
import '../booking/widgets/booking_widgets.dart';

/// What deleting the account removes and keeps, then a typed confirmation -> DELETE /profile.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _deleting = false;
  String? _error;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDeleteAccountConfirm(context);
    if (!confirmed || !mounted) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      await ref.read(localDataProvider).clearUserData();
      ref.read(authNoticeProvider.notifier).show(AuthNotice.accountDeleted);
      await ref.read(sessionManagerProvider).endSessionLocally();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = apiErrorText(e, l, fallback: l.deleteAccountFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.deleteAccount'),
      appBar: AppBar(title: Text(l.deleteAccountTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            Text(
              l.deleteAccountIntro,
              style: AppTextStyles.body.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s6),
            _Section(
              key: const Key('deleteAccount.deleted'),
              icon: Icons.delete_outline,
              iconColor: c.statusError,
              heading: l.deleteAccountDeletedHeading,
              body: l.deleteAccountDeletedBody,
            ),
            const SizedBox(height: AppSpacing.s3),
            _Section(
              key: const Key('deleteAccount.kept'),
              icon: Icons.inventory_2_outlined,
              iconColor: c.inkMuted,
              heading: l.deleteAccountKeptHeading,
              body: l.deleteAccountKeptBody,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s4),
              InlineError(_error!, key: const Key('deleteAccount.error')),
            ],
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              key: const Key('deleteAccount.continue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.statusError,
                side: BorderSide(color: c.statusError),
              ),
              onPressed: _deleting ? null : _confirmAndDelete,
              child: _deleting
                  ? SizedBox.square(
                      dimension: AppSpacing.s5,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.statusError,
                      ),
                    )
                  : Text(l.deleteAccountContinue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  body,
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// True only when the user typed the confirmation word (case and spacing ignored) and
/// tapped Delete account.
Future<bool> showDeleteAccountConfirm(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const _DeleteConfirmDialog(),
  );
  return result ?? false;
}

bool deleteConfirmationMatches(String typed, String word) =>
    typed.trim().toUpperCase() == word.trim().toUpperCase();

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final word = l.deleteAccountConfirmWord;
    final matches = deleteConfirmationMatches(_typed.text, word);
    return AlertDialog(
      key: const Key('deleteAccount.dialog'),
      title: Text(l.deleteAccountConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deleteAccountConfirmBody(word)),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            key: const Key('deleteAccount.confirmField'),
            controller: _typed,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: word),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('deleteAccount.keep'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.deleteAccountKeep),
        ),
        TextButton(
          key: const Key('deleteAccount.confirm'),
          style: TextButton.styleFrom(foregroundColor: c.statusError),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l.deleteAccountButton),
        ),
      ],
    );
  }
}
