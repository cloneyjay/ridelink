import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/auth_api.dart';
import 'auth/session.dart';
import 'auth/session_manager.dart';
import 'auth/token_storage.dart';
import 'config/app_config.dart';
import 'realtime/realtime_client.dart';
import 'realtime/realtime_event.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(appConfigProvider)),
);

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    storage: ref.watch(tokenStorageProvider),
    authApi: ref.watch(authApiProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// Session state as a Riverpod value (unknown / signedOut / signedIn).
final sessionStateProvider =
    NotifierProvider<SessionStateNotifier, SessionState>(
      SessionStateNotifier.new,
    );

class SessionStateNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final manager = ref.watch(sessionManagerProvider);
    void sync() => state = manager.state;
    manager.addListener(sync);
    ref.onDispose(() => manager.removeListener(sync));
    return manager.state;
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(appConfigProvider),
    tokens: ref.watch(sessionManagerProvider),
  ),
);

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    uri: ref.watch(appConfigProvider).webSocketUri,
    tokens: ref.watch(sessionManagerProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Keeps the realtime connection open exactly while signed in. Watch it once from the app root.
final realtimeLifecycleProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);
  void apply(SessionState state) =>
      state is SignedIn ? client.start() : client.stop();
  ref.listen<SessionState>(sessionStateProvider, (_, next) => apply(next));
  apply(ref.read(sessionStateProvider));
});

final realtimeEventsProvider = StreamProvider<RealtimeEvent>(
  (ref) => ref.watch(realtimeClientProvider).events,
);
