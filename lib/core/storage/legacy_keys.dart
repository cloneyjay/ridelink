import 'local_store.dart';

/// Keys earlier builds wrote to device storage that nothing reads any more. Live order state
/// now comes only from the server (frontend decision 14), so these are deleted on start.
const legacyStorageKeys = ['ridelink.pending_offer'];

/// Removes [legacyStorageKeys]; a no-op when they are absent, so it is safe on every start.
Future<void> removeLegacyKeys(LocalStore store) async {
  for (final key in legacyStorageKeys) {
    try {
      await store.remove(key);
    } catch (_) {
      // Storage trouble must never block startup; the next start tries again.
    }
  }
}
