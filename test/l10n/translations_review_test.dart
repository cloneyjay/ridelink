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
}
