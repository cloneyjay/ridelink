import '../../core/storage/local_store.dart';

/// Orders whose rating prompt has been shown on this device (each party is asked once).
class RatingPromptStore {
  RatingPromptStore(this._store);

  static const _key = 'ridelink.rating_prompted';
  static const _keep = 100;
  final LocalStore _store;

  bool wasPrompted(String orderId) =>
      _store.getStringList(_key).contains(orderId);

  Future<void> markPrompted(String orderId) {
    final ids = _store.getStringList(_key);
    if (ids.contains(orderId)) return Future.value();
    final next = [...ids, orderId];
    return _store.setStringList(
      _key,
      next.length > _keep ? next.sublist(next.length - _keep) : next,
    );
  }
}
