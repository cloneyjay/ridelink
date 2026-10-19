import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import 'data/notification_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.loading = false,
    this.failed = false,
  });

  final List<AppNotification> items;
  final int unread;
  final bool loading;
  final bool failed;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unread,
    bool? loading,
    bool? failed,
  }) => NotificationsState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
  );
}

/// In-app notifications for the signed-in user: the list, the unread badge, and live
/// `notification.created` events. Rebuilt when the user changes.
final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const NotificationsState();
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) _onEvent(event);
    });
    Future.microtask(load);
    return const NotificationsState(loading: true);
  }

  Future<void> load() async {
    if (ref.read(currentUserIdProvider) == null) return;
    state = state.copyWith(loading: true, failed: false);
    try {
      final page = await ref.read(notificationRepositoryProvider).list();
      state = NotificationsState(items: page.items, unread: page.unreadCount);
    } catch (_) {
      state = state.copyWith(loading: false, failed: true);
    }
  }

  void _onEvent(RealtimeEvent event) {
    switch (event.kind) {
      case RealtimeEventKind.notificationCreated:
        final n = AppNotification.fromJson(event.data);
        if (n.id.isEmpty || state.items.any((i) => i.id == n.id)) return;
        state = state.copyWith(
          items: [n, ...state.items],
          unread: state.unread + 1,
        );
      case RealtimeEventKind.connected:
        // Catch up on anything sent while the socket was down.
        unawaited(load());
      default:
        return;
    }
  }

  /// Marks [id] read locally at once, then on the server; a failed call is retried on the next load.
  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((n) => n.id == id);
    if (index < 0 || state.items[index].isRead) return;
    final items = [...state.items];
    items[index] = items[index].markedRead(ref.read(clockProvider)());
    state = state.copyWith(
      items: items,
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
    } catch (_) {}
  }
}
