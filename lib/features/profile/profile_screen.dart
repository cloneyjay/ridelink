import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../auth/auth_validators.dart';
import '../booking/widgets/booking_widgets.dart';
import '../common/confirm_dialog.dart';
import '../orders/data/order_models.dart';
import '../rider/data/rider_models.dart';

final profileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ref.watch(accountRepositoryProvider).profile(),
  retry: (_, _) => null,
);

/// A verified rider's name must match their ID, so it changes only through support
/// (auth-onboarding decision 15).
final nameLockedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final rider = await ref.watch(riderRepositoryProvider).me();
    return rider?.verificationStatus == VerificationStatus.verified;
  } catch (_) {
    return false;
  }
}, retry: (_, _) => null);

/// Profile & account: names (editable unless a verified rider), email (read-only), language
/// note (follows the device), sign out, delete account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    Widget body;
    if (profile.hasError && !profile.hasValue) {
      body = MessageView(
        key: const Key('profile.error'),
        icon: Icons.wifi_off,
        title: l.profileLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('profile.retry'),
        onAction: () => ref.invalidate(profileProvider),
      );
    } else if (!profile.hasValue) {
      body = const LoadingView();
    } else {
      body = _ProfileForm(profile: profile.value!);
    }
    return Scaffold(
      key: const Key('screen.profile'),
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(child: body),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  bool _saving = false;
  bool _lockedByServer = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  bool get _changed =>
      _first.text.trim() != widget.profile.firstName ||
      _last.text.trim() != widget.profile.lastName;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .updateName(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      ref.invalidate(profileProvider);
      showSnack(context, l.profileSaved, key: const Key('profile.saved'));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.statusCode == 403) {
          _lockedByServer = true;
        } else {
          _error = apiErrorText(e, l, fallback: l.profileSaveFailed);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = apiErrorText(e, l, fallback: l.profileSaveFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final locked =
        _lockedByServer || (ref.watch(nameLockedProvider).value ?? false);
    return ListView(
      padding: const EdgeInsets.all(AppLayout.screenPadding),
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('profile.firstName'),
                controller: _first,
                enabled: !locked && !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.firstNameLabel),
                validator: (v) => validateFirstName(v, l),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.s3),
              TextFormField(
                key: const Key('profile.lastName'),
                controller: _last,
                enabled: !locked && !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.lastNameLabel),
                validator: (v) => validateLastName(v, l),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        NoteRow(
          locked ? l.profileNameLocked : l.profileNameShownAs,
          key: Key(locked ? 'profile.locked' : 'profile.shownAs'),
          icon: locked ? Icons.lock_outline : Icons.info_outline,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s3),
          InlineError(_error!, key: const Key('profile.saveError')),
        ],
        if (!locked) ...[
          const SizedBox(height: AppSpacing.s4),
          PrimaryButton(
            key: const Key('profile.save'),
            label: l.profileSave,
            loading: _saving,
            onPressed: _changed ? _save : null,
          ),
        ],
        const SizedBox(height: AppSpacing.s6),
        _InfoRow(
          key: const Key('profile.email'),
          label: l.emailLabel,
          value: widget.profile.email,
        ),
        const SizedBox(height: AppSpacing.s3),
        _InfoRow(
          key: const Key('profile.language'),
          label: l.profileLanguage,
          value: l.profileLanguageValue,
        ),
        const SizedBox(height: AppSpacing.s8),
        OutlinedButton.icon(
          key: const Key('profile.signOut'),
          onPressed: () => ref.read(sessionManagerProvider).signOut(),
          icon: Icon(Icons.logout, color: c.statusError),
          label: Text(
            l.menuSignOut,
            style: AppTextStyles.labelLg.copyWith(color: c.statusError),
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        TextButton.icon(
          key: const Key('profile.deleteAccount'),
          style: TextButton.styleFrom(foregroundColor: c.statusError),
          onPressed: () => context.push(AppRoutes.deleteAccount),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.deleteAccountButton),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm.copyWith(color: c.inkMuted)),
        const SizedBox(height: AppSpacing.s1),
        Text(value, style: AppTextStyles.body.copyWith(color: c.ink)),
      ],
    );
  }
}
