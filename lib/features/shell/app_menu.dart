import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session.dart';
import '../../core/mode/app_mode.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../common/confirm_dialog.dart';
import '../rider/rider_controller.dart';

enum AppSide { sender, rider }

/// Why the rider can't switch to sending right now (frontend decision 13).
enum SwitchToSendingBlock { none, activeJob, online }

SwitchToSendingBlock switchToSendingBlock(RiderState s) {
  if (s.job?.isActiveJob ?? false) return SwitchToSendingBlock.activeJob;
  if (s.online) return SwitchToSendingBlock.online;
  return SwitchToSendingBlock.none;
}

/// Mid-job: refuse. Online: ask to go offline first. Returns true when the switch may go ahead.
Future<bool> confirmSwitchToSending(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final controller = ref.read(riderControllerProvider.notifier);
  switch (switchToSendingBlock(ref.read(riderControllerProvider))) {
    case SwitchToSendingBlock.none:
      return true;
    case SwitchToSendingBlock.activeJob:
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('menu.midJobDialog'),
          title: Text(l.switchMidJobTitle),
          content: Text(l.switchMidJobBody),
          actions: [
            TextButton(
              key: const Key('menu.midJobDialog.ok'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.doneButton),
            ),
          ],
        ),
      );
      return false;
    case SwitchToSendingBlock.online:
      final ok = await confirmDialog(
        context,
        keyPrefix: 'menu.goOfflineDialog',
        title: l.switchGoOfflineTitle,
        body: l.switchGoOfflineBody,
        confirmLabel: l.switchGoOfflineConfirm,
        cancelLabel: l.switchStayOnline,
      );
      if (!ok) return false;
      await controller.setOnline(false);
      if (ref.read(riderControllerProvider).online) {
        if (context.mounted) {
          showSnack(
            context,
            l.switchGoOfflineFailed,
            key: const Key('menu.goOfflineFailed'),
          );
        }
        return false;
      }
      return true;
  }
}

/// Side menu shared by both modes: mode switch (riders only) and sign out.
class AppMenuDrawer extends ConsumerWidget {
  const AppMenuDrawer({super.key, required this.side});

  final AppSide side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final session = ref.watch(sessionStateProvider);
    final email = session is SignedIn ? session.session.user.email : null;

    void go(String location) {
      Navigator.of(context).pop();
      context.go(location);
    }

    Widget modeEntry() {
      if (side == AppSide.rider) {
        return _MenuItem(
          key: const Key('menu.switchToSending'),
          icon: Symbols.package_2,
          label: l.menuSwitchToSending,
          onTap: () async {
            if (!await confirmSwitchToSending(context, ref)) return;
            if (context.mounted) go(AppRoutes.home);
          },
        );
      }
      return ref
          .watch(isRiderProvider)
          .when(
            data: (isRider) => isRider
                ? _MenuItem(
                    key: const Key('menu.switchToRiding'),
                    icon: Symbols.two_wheeler,
                    label: l.menuSwitchToRiding,
                    onTap: () => go(AppRoutes.riderHome),
                  )
                : _MenuItem(
                    key: const Key('menu.becomeRider'),
                    icon: Symbols.two_wheeler,
                    label: l.menuBecomeRider,
                    onTap: () => go(AppRoutes.riderOnboarding),
                  ),
            loading: () => SizedBox(
              key: const Key('menu.riderStatusLoading'),
              height: AppLayout.minTapTarget,
              child: Center(
                child: SizedBox.square(
                  dimension: AppSpacing.s5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.brand500,
                  ),
                ),
              ),
            ),
            error: (_, _) => _MenuItem(
              key: const Key('menu.riderStatusError'),
              icon: Icons.refresh,
              label: l.menuRiderStatusError,
              trailing: l.retryButton,
              onTap: () => ref.invalidate(isRiderProvider),
            ),
          );
    }

    return Drawer(
      key: const Key('menu.drawer'),
      backgroundColor: c.surfaceRaised,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.appName,
                    style: AppTextStyles.displayMd.copyWith(color: c.ink),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      email,
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            const Divider(),
            modeEntry(),
            _MenuItem(
              key: const Key('menu.history'),
              icon: Icons.receipt_long_outlined,
              label: l.menuHistory,
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                  AppRoutes.historyFor(
                    side == AppSide.rider ? AppMode.rider : AppMode.sender,
                  ),
                );
              },
            ),
            _MenuItem(
              key: const Key('menu.profile'),
              icon: Icons.person_outline,
              label: l.menuProfile,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.profile);
              },
            ),
            _MenuItem(
              key: const Key('menu.signOut'),
              icon: Icons.logout,
              label: l.menuSignOut,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(sessionManagerProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.screenPadding,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              Icon(icon, color: c.inkMuted),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTextStyles.label.copyWith(color: c.brand500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round menu button floating over the map.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        shape: BoxShape.circle,
        boxShadow: context.shadows.md,
      ),
      child: IconButton(
        key: const Key('menu.open'),
        tooltip: AppLocalizations.of(context).menuTooltip,
        constraints: const BoxConstraints(
          minWidth: AppLayout.minTapTarget,
          minHeight: AppLayout.minTapTarget,
        ),
        icon: Icon(Icons.menu, color: c.ink),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}
