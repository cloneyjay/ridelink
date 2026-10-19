import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Swahili strings are drafted by engineering and marked "x-review": "needs-review" until a
/// fluent reviewer signs them off. This reports the outstanding count without failing the build.
void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  test('reports Swahili entries still awaiting review (fail-soft)', () {
    final sw = load('app_sw.arb');
    final pending = <String>[
      for (final entry in sw.entries)
        if (entry.key.startsWith('@') && !entry.key.startsWith('@@'))
          if ((entry.value as Map)['x-review'] == 'needs-review')
            entry.key.substring(1),
    ];

    // ignore: avoid_print
    print(
      'Swahili strings awaiting review: ${pending.length}${pending.isEmpty ? '' : ' -> ${pending.join(', ')}'}',
    );
  });

  test('every English key has a Swahili entry', () {
    Set<String> keys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys(load('app_sw.arb')), containsAll(keys(load('app_en.arb'))));
  });

  test('English and Swahili have exactly the same keys', () {
    Set<String> keys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();
    final en = keys(load('app_en.arb'));
    final sw = keys(load('app_sw.arb'));
    expect(sw.difference(en), isEmpty, reason: 'Swahili-only keys');
    expect(en.difference(sw), isEmpty, reason: 'English-only keys');
  });

  test(
    'deleted strings are gone from the ARBs, generated code and sources',
    () {
      const deleted = [
        'evidencePickupPhotoHintRide',
        'evidenceHandoverPhotoHintRide',
      ];
      final offenders = <String>[];
      for (final dir in ['lib', 'test']) {
        for (final f in Directory(dir).listSync(recursive: true)) {
          if (f is! File) continue;
          if (!f.path.endsWith('.dart') && !f.path.endsWith('.arb')) continue;
          if (f.uri.pathSegments.last == 'translations_review_test.dart') {
            continue;
          }
          final src = f.readAsStringSync();
          for (final key in deleted) {
            if (src.contains(key)) offenders.add('${f.path}: $key');
          }
        }
      }
      expect(offenders, isEmpty);
    },
  );
}
