import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_payload.dart';

/// Notification taps, held until the user is signed in.
class PushTaps {
  final _controller = StreamController<PushPayload>.broadcast();
  PushPayload? _pending;

  Stream<PushPayload> get stream => _controller.stream;

  void add(PushPayload? p) {
    if (p == null) return;
    _pending = p;
    _controller.add(p);
  }

  PushPayload? take() {
    final p = _pending;
    _pending = null;
    return p;
  }

  Future<void> dispose() => _controller.close();
}

/// Overridden in main() with the instance the local-notification plugin reports into.
final pushTapsProvider = Provider<PushTaps>((ref) {
  final taps = PushTaps();
  ref.onDispose(taps.dispose);
  return taps;
});
