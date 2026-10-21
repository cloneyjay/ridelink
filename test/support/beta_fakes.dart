import 'dart:async';

import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/navigation/url_opener.dart';
import 'package:ridelink/core/push/device_registrar.dart';
import 'package:ridelink/core/push/local_notifier.dart';
import 'package:ridelink/core/push/notification_permission.dart';
import 'package:ridelink/core/push/push_messaging.dart';
import 'package:ridelink/core/version/version_gate.dart';
import 'package:ridelink/features/legal/legal_repository.dart';
import 'package:ridelink/l10n/app_localizations.dart';

const legalDocsFixture = LegalDocs(
  terms: LegalDocument(
    version: '2026-10-01',
    url: 'https://ridelink.test/terms',
  ),
  privacy: LegalDocument(
    version: '2026-10-02',
    url: 'https://ridelink.test/privacy',
  ),
);

class FakeLegalRepository implements LegalRepository {
  LegalDocs docs = legalDocsFixture;
  Object? currentError;
  int currentCalls = 0;
  final acceptCalls = <({String terms, String privacy})>[];
  Object? acceptError;

  @override
  Future<LegalDocs> current() async {
    currentCalls++;
    if (currentError != null) throw currentError!;
    return docs;
  }

  @override
  Future<void> accept({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    acceptCalls.add((terms: termsVersion, privacy: privacyVersion));
    if (acceptError != null) throw acceptError!;
  }
}

class FakeUrlOpener implements UrlOpener {
  FakeUrlOpener({this.result = true});

  bool result;
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

class FakeDeviceApi implements DeviceApi {
  final registered = <({String token, String appVersion})>[];
  final unregistered = <String>[];
  Object? registerError;
  Object? unregisterError;
  Completer<void>? unregisterGate;

  @override
  Future<void> register({
    required String token,
    required String appVersion,
  }) async {
    registered.add((token: token, appVersion: appVersion));
    if (registerError != null) throw registerError!;
  }

  @override
  Future<void> unregister(String token) async {
    unregistered.add(token);
    if (unregisterGate != null) await unregisterGate!.future;
    if (unregisterError != null) throw unregisterError!;
  }
}

class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.currentToken = 'fcm-1', this.available = true});

  String? currentToken;
  @override
  final bool available;
  final refreshes = StreamController<String>.broadcast();
  final messages = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => messages.stream;

  Future<void> close() async {
    await refreshes.close();
    await messages.close();
  }
}

class FakeLocalNotifier implements LocalNotifier {
  final shown = <LocalPushNotification>[];
  int initializations = 0;
  String? launch;

  @override
  Future<void> initialize({
    required AppLocalizations strings,
    void Function(String? payload)? onTap,
  }) async => initializations++;

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<void> show(LocalPushNotification n) async => shown.add(n);
}

class FakeNotificationPermission implements NotificationPermission {
  FakeNotificationPermission({
    this.current = NotificationPermissionStatus.canAsk,
    this.afterRequest = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus current;
  NotificationPermissionStatus afterRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<NotificationPermissionStatus> status() async => current;

  @override
  Future<NotificationPermissionStatus> request() async {
    requests++;
    return current = afterRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeAppConfigRepository implements AppConfigRepository {
  FakeAppConfigRepository({this.config, this.error});

  RemoteAppConfig? config;
  Object? error;
  int calls = 0;

  @override
  Future<RemoteAppConfig> fetch() async {
    calls++;
    if (error != null) throw error!;
    return config ?? const RemoteAppConfig();
  }
}

const offlineError = ApiException(message: 'connection refused');
