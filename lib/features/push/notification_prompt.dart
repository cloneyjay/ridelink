import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/push/notification_permission.dart';
import '../../core/push/push_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// After sign-in: asks once per install for POST_NOTIFICATIONS (Android 13+). Riders first see
/// why (offers arrive as notifications). A refusal never blocks anything.
Future<void> maybeAskNotificationPermission(
  BuildContext context,
  WidgetRef ref, {
  required bool explain,
}) async {
  final prefs = ref.read(pushPreferencesProvider);
  if (prefs.asking || prefs.notificationsAsked) return;
  prefs.asking = true;
  try {
    final permission = ref.read(notificationPermissionProvider);
    if (await permission.status() != NotificationPermissionStatus.canAsk) {
      return;
    }
    await prefs.markNotificationsAsked();
    if (!context.mounted) return;
    if (explain && !await _explain(context)) return;
    await permission.request();
  } finally {
    prefs.asking = false;
    if (context.mounted) ref.invalidate(notificationsAllowedProvider);
  }
}

Future<bool> _explain(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('notifPermission.dialog'),
      icon: const Icon(Icons.notifications_active_outlined),
      title: Text(l.notifPermissionTitle),
      content: Text(l.notifPermissionBody),
      actions: [
        TextButton(
          key: const Key('notifPermission.notNow'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.notifPermissionNotNow),
        ),
        TextButton(
          key: const Key('notifPermission.continue'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.notifPermissionContinue),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shown next to the rider's online toggle while notifications are not allowed.
class NotificationsOffNote extends ConsumerStatefulWidget {
  const NotificationsOffNote({super.key});

  @override
  ConsumerState<NotificationsOffNote> createState() =>
      _NotificationsOffNoteState();
}

class _NotificationsOffNoteState extends ConsumerState<NotificationsOffNote> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from system settings: pick up a newly granted permission.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsAllowedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _turnOn() async {
    final permission = ref.read(notificationPermissionProvider);
    if (await permission.status() == NotificationPermissionStatus.canAsk) {
      await permission.request();
    } else {
      await permission.openSettings();
    }
    if (mounted) ref.invalidate(notificationsAllowedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    if (allowed) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Container(
        key: const Key('riderHome.notificationsOff'),
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: c.inkMuted),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                l.notifOffReminder,
                style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            TextButton(
              key: const Key('riderHome.notificationsOn'),
              onPressed: () => unawaited(_turnOn()),
              child: Text(l.notifOffTurnOn),
            ),
          ],
        ),
      ),
    );
  }
}
