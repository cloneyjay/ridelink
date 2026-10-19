import '../../../core/api/api_client.dart';
import '../../booking/data/booking_models.dart' show parseTime;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  /// From GET /notifications rows and realtime `notification.created` payloads.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final orderId = json['order_id'] ?? data['order_id'];
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      orderId: orderId is String && orderId.isNotEmpty ? orderId : null,
      data: data,
      readAt: parseTime(json['read_at']),
      createdAt: parseTime(json['created_at']),
    );
  }

  final String id;
  final String type;

  /// English fallbacks from the server; the app renders known types itself.
  final String title;
  final String body;
  final String? orderId;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    orderId: orderId,
    data: data,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );
}

class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;
}

abstract class NotificationRepository {
  Future<NotificationPage> list();

  Future<void> markRead(String id);
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);

  final ApiClient _api;

  @override
  Future<NotificationPage> list() async {
    final data = (await _api.get('notifications') as Map)
        .cast<String, dynamic>();
    return NotificationPage(
      items: [
        for (final n in (data['notifications'] as List? ?? const []))
          AppNotification.fromJson((n as Map).cast<String, dynamic>()),
      ],
      unreadCount: (data['unread_count'] as num? ?? 0).toInt(),
    );
  }

  @override
  Future<void> markRead(String id) async {
    await _api.patch('notifications/$id/read');
  }
}
