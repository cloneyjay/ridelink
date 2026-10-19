import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/storage/legacy_keys.dart';
import 'package:ridelink/core/storage/local_store.dart';

class _FailingStore extends MemoryLocalStore {
  @override
  Future<void> remove(String key) async => throw StateError('disk');
}

void main() {
  test(
    'removes the orphaned pending-offer key and keeps preferences',
    () async {
      final store = MemoryLocalStore()
        ..values['ridelink.pending_offer'] = '{"offer":"o-1"}'
        ..values['ridelink.mode'] = 'rider';
      await removeLegacyKeys(store);
      expect(store.values.containsKey('ridelink.pending_offer'), isFalse);
      expect(store.values['ridelink.mode'], 'rider');
    },
  );

  test('is a no-op when the key is absent, and safe to repeat', () async {
    final store = MemoryLocalStore()..values['ridelink.mode'] = 'sender';
    await removeLegacyKeys(store);
    await removeLegacyKeys(store);
    expect(store.values, {'ridelink.mode': 'sender'});
  });

  test('a storage failure never blocks startup', () async {
    await expectLater(removeLegacyKeys(_FailingStore()), completes);
  });

  test('runs on startup, and the cleanup only ever deletes', () {
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('removeLegacyKeys('),
    );
    final src = File('lib/core/storage/legacy_keys.dart').readAsStringSync();
    expect(src, isNot(contains('setString')));
    expect(src, isNot(contains('getString')));
  });
}
