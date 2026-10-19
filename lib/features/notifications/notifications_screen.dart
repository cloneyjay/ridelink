import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../orders/order_providers.dart';
import '../rider/rider_labels.dart';
import 'data/notification_repository.dart';
import 'notification_text.dart';
import 'notifications_controller.dart';

/// Bell with the unread count; opens the notifications list.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.floating = false});

  /// Round raised button for use over the map.
  final bool floating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final unread = ref.watch(notificationsProvider.select((s) => s.unread));
    final button = IconButton(
      key: const Key('notifications.bell'),
      tooltip: l.notificationsTitle,
      constraints: const BoxConstraints(
        minWidth: AppLayout.minTapTarget,
        minHeight: AppLayout.minTapTarget,
      ),
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        key: const Key('notifications.badge'),
        isLabelVisible: unread > 0,
        backgroundColor: c.brand500,
        textColor: c.inkOnBrand,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          key: const Key('notifications.badge.count'),
        ),
        child: Icon(Icons.notifications_outlined, color: c.ink),
      ),
    );
    if (!floating) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        shape: BoxShape.circle,
        boxShadow: context.shadows.md,
      ),
      child: button,
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _opening;

  /// Marks read, then deep-links: documents for document notices, else the order.
  Future<void> _open(AppNotification n) async {
    if (_opening != null) return;
    ref.read(notificationsProvider.notifier).markRead(n.id);
    if (n.type.startsWith('document_')) {
      context.push(AppRoutes.riderDocuments);
      return;
    }
    final orderId = n.orderId;
    if (orderId == null) return;
    setState(() => _opening = n.id);
    var target = AppRoutes.orderDetailFor(orderId);
    var live = false;
    try {
      final details = await ref.read(ordersRepositoryProvider).details(orderId);
      target = routeForOrder(details, ref.read(currentUserIdProvider));
      live = details.order.isActiveJob;
    } catch (_) {
      // The detail screen shows its own error and retry.
    }
    if (!mounted) return;
    setState(() => _opening = null);
    // Live screens replace the stack, like the home screen's resume does.
    live ? context.go(target) : context.push(target);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);

    Widget body;
    if (s.items.isEmpty && s.loading) {
      body = const LoadingView();
    } else if (s.items.isEmpty && s.failed) {
      body = MessageView(
        key: const Key('notifications.error'),
        icon: Icons.wifi_off,
        title: l.notificationsLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('notifications.retry'),
        onAction: controller.load,
      );
    } else if (s.items.isEmpty) {
      body = MessageView(
        key: const Key('notifications.empty'),
        icon: Icons.notifications_none,
        title: l.notificationsEmpty,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          itemCount: s.items.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) => _NotificationTile(
            notification: s.items[i],
            busy: _opening == s.items[i].id,
            onTap: () => _open(s.items[i]),
          ),
        ),
      );
    }
    return Scaffold(
      key: const Key('screen.notifications'),
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: SafeArea(child: body),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.busy,
    required this.onTap,
  });

  final AppNotification notification;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final n = notification;
    final text = notificationText(n, l);
    final created = n.createdAt;
    return InkWell(
      key: Key('notification.${n.id}'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.screenPadding,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s2),
                child: Container(
                  key: n.isRead ? null : Key('notification.${n.id}.unread'),
                  width: AppSpacing.s2,
                  height: AppSpacing.s2,
                  decoration: BoxDecoration(
                    color: n.isRead ? null : c.brand500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
                      style:
                          (n.isRead
                                  ? AppTextStyles.body
                                  : AppTextStyles.labelLg)
                              .copyWith(color: c.ink),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      text.body,
                      style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                    ),
                    if (created != null)
                      Text(
                        formatDateTime(l, created),
                        style: AppTextStyles.labelSm.copyWith(
                          color: c.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              if (busy)
                SizedBox.square(
                  dimension: AppSpacing.s5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.brand500,
                  ),
                )
              else if (n.orderId != null || n.type.startsWith('document_'))
                Icon(Icons.chevron_right, color: c.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
