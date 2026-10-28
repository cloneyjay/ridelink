import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import 'public_profile_models.dart';
import 'public_profile_providers.dart';
import 'public_profile_view.dart';

/// "Your public profile": the caller's own profile exactly as the other side receives it.
/// A user with a rider profile can switch between the sender and rider views.
class MyPublicProfileScreen extends ConsumerStatefulWidget {
  const MyPublicProfileScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const MyPublicProfileScreen()),
  );

  @override
  ConsumerState<MyPublicProfileScreen> createState() =>
      _MyPublicProfileScreenState();
}

class _MyPublicProfileScreenState extends ConsumerState<MyPublicProfileScreen> {
  PublicProfileRole? _role;

  /// Set when the server says this user has no rider profile (404 on role=rider).
  bool _noRiderProfile = false;

  static bool _is404(Object? e) => e is ApiException && e.statusCode == 404;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isRider =
        !_noRiderProfile && (ref.watch(isRiderProvider).value ?? false);
    final preferred = isRider && ref.read(appModeProvider).mode == AppMode.rider
        ? PublicProfileRole.rider
        : PublicProfileRole.sender;
    final role = isRider ? (_role ?? preferred) : PublicProfileRole.sender;
    final provider = myPublicProfileProvider(role);

    final profile = ref.watch(provider);
    if (role == PublicProfileRole.rider && _is404(profile.error)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _noRiderProfile = true);
      });
    }
    final Widget content;
    if (profile.hasValue && !profile.hasError) {
      content = PublicProfileView(profile: profile.value!);
    } else if (profile.hasError) {
      content = _is404(profile.error) && role == PublicProfileRole.rider
          ? const SizedBox.shrink()
          : MessageView(
              key: const Key('myPublicProfile.error'),
              icon: Icons.wifi_off,
              title: l.publicProfileLoadFailed,
              actionLabel: l.retryButton,
              actionKey: const Key('myPublicProfile.retry'),
              onAction: () => ref.invalidate(provider),
            );
    } else {
      content = const SizedBox(
        height: AppSpacing.s16 * 2,
        child: LoadingView(),
      );
    }

    return Scaffold(
      key: const Key('screen.myPublicProfile'),
      appBar: AppBar(title: Text(l.publicProfileYours)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            if (isRider) ...[
              Row(
                key: const Key('myPublicProfile.role'),
                children: [
                  Expanded(
                    child: _RoleOption(
                      key: const Key('myPublicProfile.role.sender'),
                      label: l.detailSender,
                      selected: role == PublicProfileRole.sender,
                      onTap: () =>
                          setState(() => _role = PublicProfileRole.sender),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: _RoleOption(
                      key: const Key('myPublicProfile.role.rider'),
                      label: l.detailRider,
                      selected: role == PublicProfileRole.rider,
                      onTap: () =>
                          setState(() => _role = PublicProfileRole.rider),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
            NoteRow(
              role == PublicProfileRole.sender
                  ? l.publicProfileRidersSee
                  : l.publicProfileSendersSee,
              key: const Key('myPublicProfile.subtitle'),
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: AppSpacing.s4),
            content,
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.brand500 : c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
              minWidth: AppLayout.minTapTarget,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Text(
                  label,
                  style: AppTextStyles.labelLg.copyWith(
                    color: selected ? c.inkOnBrand : c.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
