import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/format/money.dart';
import '../../../core/location/location_service.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../../common/confirm_dialog.dart';
import '../../notifications/notifications_screen.dart';
import '../../shell/app_menu.dart';
import '../job/rider_job_view.dart';
import '../offer/rider_offer_view.dart';
import '../rider_controller.dart';
import '../rider_labels.dart';

/// Rider side root: shows the active job, else a pending offer (screen 6), else the idle home
/// with the online toggle.
class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appModeProvider).set(AppMode.rider);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OfferEnd?>(
      riderControllerProvider.select((s) => s.lastOfferEnd),
      (_, end) {
        if (end == null) return;
        final l = AppLocalizations.of(context);
        showSnack(context, switch (end) {
          OfferEnd.expired => l.riderOfferExpired,
          OfferEnd.declined => l.riderOfferDeclined,
          OfferEnd.taken => l.riderOfferTaken,
          OfferEnd.cancelled => l.riderOfferCancelled,
        }, key: const Key('riderHome.offerEnded'));
        ref.read(riderControllerProvider.notifier).clearOfferEnd();
      },
    );

    final s = ref.watch(riderControllerProvider);
    final l = AppLocalizations.of(context);
    if (s.job != null) return RiderJobView(order: s.job!);
    if (s.offer != null) return RiderOfferView(offer: s.offer!);

    Widget body;
    if (s.loading && !s.registered) {
      body = const LoadingView();
    } else if (s.loadFailed && !s.registered) {
      body = MessageView(
        key: const Key('riderHome.error'),
        icon: Icons.wifi_off,
        title: l.riderLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('riderHome.retry'),
        onAction: () => ref.read(riderControllerProvider.notifier).load(),
      );
    } else if (!s.registered) {
      body = MessageView(
        key: const Key('riderHome.notRegistered'),
        icon: Symbols.two_wheeler,
        title: l.riderNotRegisteredTitle,
        actionLabel: l.menuBecomeRider,
        actionKey: const Key('riderHome.register'),
        onAction: () => context.go(AppRoutes.riderOnboarding),
      );
    } else {
      body = _IdleHome(state: s);
    }
    return Scaffold(
      key: const Key('screen.riderHome'),
      appBar: AppBar(
        title: Text(l.riderHomeTitle),
        actions: const [NotificationBell()],
      ),
      drawer: const AppMenuDrawer(side: AppSide.rider),
      body: SafeArea(child: body),
    );
  }
}

class _IdleHome extends ConsumerWidget {
  const _IdleHome({required this.state});

  final RiderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final controller = ref.read(riderControllerProvider.notifier);
    final profile = state.profile!;
    final online = state.online;
    final block = state.block;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPadding),
        children: [
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: AppSpacing.s3,
                  height: AppSpacing.s3,
                  decoration: BoxDecoration(
                    color: online ? c.statusSuccess : c.inkFaint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        online ? l.riderOnline : l.riderOffline,
                        key: const Key('riderHome.status'),
                        style: AppTextStyles.displaySm.copyWith(color: c.ink),
                      ),
                      Text(
                        online
                            ? l.riderOnlineBody(
                                formatKm(profile.pickupRadiusKm),
                              )
                            : l.riderOfflineBody,
                        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                SizedBox(
                  height: AppLayout.minTapTarget,
                  child: state.toggling
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          child: SizedBox.square(
                            dimension: AppSpacing.s5,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.brand500,
                            ),
                          ),
                        )
                      : Switch(
                          key: const Key('riderHome.onlineSwitch'),
                          value: online,
                          activeTrackColor: c.statusSuccess,
                          onChanged: (v) => controller.setOnline(v),
                        ),
                ),
              ],
            ),
          ),
          if (block != null) ...[
            const SizedBox(height: AppSpacing.s3),
            _BlockCard(block: block),
          ],
          const SizedBox(height: AppSpacing.s6),
          _NavTile(
            key: const Key('riderHome.settings'),
            icon: Icons.tune,
            title: l.settingsTitle,
            subtitle: l.riderSettingsSummary(
              formatKm(profile.pickupRadiusKm),
              formatKesRate(profile.deliveryPricePerKm),
              formatKesRate(profile.ridePricePerKm),
            ),
            onTap: () => context.push(AppRoutes.riderSettings),
          ),
          const SizedBox(height: AppSpacing.s3),
          _NavTile(
            key: const Key('riderHome.documents'),
            icon: Icons.badge_outlined,
            title: l.documentsTitle,
            subtitle: l.riderPlate(profile.plateNumber),
            onTap: () => context.push(AppRoutes.riderDocuments),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({required this.block});

  final OnlineBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final location = ref.read(locationServiceProvider);
    final controller = ref.read(riderControllerProvider.notifier);
    final (
      String key,
      String title,
      String body,
      String? action,
      VoidCallback? onAction,
    ) = switch (block) {
      BlockNotVerified() => (
        'riderHome.block.notVerified',
        l.blockNotVerifiedTitle,
        l.blockNotVerifiedBody,
        l.viewStatusButton,
        () => context.push(AppRoutes.riderVerification),
      ),
      BlockDocuments(:final documents) => (
        'riderHome.block.documents',
        l.blockDocumentsTitle,
        documents.isEmpty
            ? l.blockDocumentsBodyGeneric
            : l.blockDocumentsBody(
                documents.map((d) => docName(l, d)).join(', '),
              ),
        l.updateDocumentsButton,
        () => context.push(AppRoutes.riderDocuments),
      ),
      BlockPaused(:final until, :final reason, :final failures) => (
        'riderHome.block.paused',
        l.blockPausedTitle(formatDateTime(l, until)),
        reason == 'missed_pickups' && failures > 0
            ? l.blockPausedMissedPickups(failures)
            : l.blockPausedBody,
        null,
        null,
      ),
      BlockLocation(:final result) => (
        'riderHome.block.location',
        l.blockLocationTitle,
        result is LocationServiceOff
            ? l.locationServiceOffBody
            : l.blockLocationBody,
        switch (result) {
          LocationDeniedForever() => l.locationOpenSettings,
          LocationServiceOff() => l.locationTurnOn,
          _ => l.locationAllow,
        },
        switch (result) {
          LocationDeniedForever() => location.openAppSettings,
          LocationServiceOff() => location.openLocationSettings,
          _ => () => controller.setOnline(true),
        },
      ),
      BlockError(:final error) => (
        'riderHome.block.error',
        l.blockErrorTitle,
        apiErrorText(error, l),
        null,
        null,
      ),
    };
    return Container(
      key: Key(key),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: c.statusWarning),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  body,
                  key: const Key('riderHome.block.body'),
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
                if (action != null && onAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s2),
                    child: TextButton(
                      key: const Key('riderHome.block.action'),
                      onPressed: onAction,
                      child: Text(action),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                Icon(icon, color: c.inkMuted),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
