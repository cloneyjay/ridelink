import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/navigation/navigation_launcher.dart';

void main() {
  const point = GeoPoint(-1.2648, 36.8025);

  test('navigation URIs: Maps intent, then geo:, then the web link', () {
    final uris = navigationUris(point).map((u) => u.toString()).toList();
    expect(uris, [
      'google.navigation:q=-1.2648,36.8025',
      'geo:-1.2648,36.8025?q=-1.2648,36.8025',
      'https://www.google.com/maps/dir/?api=1&destination=-1.2648%2C36.8025',
    ]);
  });

  test('the first URI an app handles wins', () async {
    final tried = <String>[];
    final launcher = UrlNavigationLauncher(
      open: (uri) async {
        tried.add(uri.scheme);
        return uri.scheme == 'google.navigation';
      },
    );
    expect(await launcher.navigateTo(point), isTrue);
    expect(tried, ['google.navigation']);
  });

  test('falls back to geo: and then the web link', () async {
    final tried = <String>[];
    final launcher = UrlNavigationLauncher(
      open: (uri) async {
        tried.add(uri.scheme);
        if (uri.scheme == 'google.navigation') throw Exception('no handler');
        return uri.scheme == 'https';
      },
    );
    expect(await launcher.navigateTo(point), isTrue);
    expect(tried, ['google.navigation', 'geo', 'https']);
  });

  test('reports failure when nothing opens', () async {
    final launcher = UrlNavigationLauncher(open: (_) async => false);
    expect(await launcher.navigateTo(point), isFalse);
  });

  test('the foreground-service notification has a monochrome drawable', () {
    final icon = File('android/app/src/main/res/drawable/ic_stat_ridelink.xml');
    expect(icon.existsSync(), isTrue);
    expect(icon.readAsStringSync(), contains('<vector'));
  });
}
