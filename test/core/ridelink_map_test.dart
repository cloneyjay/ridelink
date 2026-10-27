import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/map/map_config.dart';
import 'package:ridelink/core/map/ridelink_map.dart';
import 'package:ridelink/core/version/client_info.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_colors.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../support/map_fakes.dart';

const _pickup = GeoPoint(-1.2648, 36.8025);
const _dropoff = GeoPoint(-1.2833, 36.8219);
const _rider = GeoPoint(-1.27, 36.81);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester, {
    MapEngine? engine,
    ThemeData? theme,
    Locale locale = const Locale('en'),
    List<MapMarker> markers = const [],
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [mapEngineProvider.overrideWithValue(engine)],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RideLinkMap(
            initialCenter: _pickup,
            initialZoom: 14,
            markers: markers,
          ),
        ),
      ),
    ),
  );

  const attribution =
      '© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors';

  testWidgets('no engine: placeholder, no attribution', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('home.mapPlaceholder')), findsOneWidget);
    expect(find.byKey(const Key('map.attribution')), findsNothing);
  });

  testWidgets('attribution is always visible over the map', (tester) async {
    await pump(tester, engine: FakeMapEngine());
    expect(find.byKey(const Key('fakeMap')), findsOneWidget);
    expect(find.text(attribution), findsOneWidget);
  });

  testWidgets('Swahili keeps the attribution names', (tester) async {
    await pump(tester, engine: FakeMapEngine(), locale: const Locale('sw'));
    expect(find.text(attribution), findsOneWidget);
  });

  testWidgets('light theme uses the light style, dark the dark style', (
    tester,
  ) async {
    final engine = FakeMapEngine();
    await pump(tester, engine: engine);
    expect(engine.spec!.styleUrl, MapConfig.lightStyleUrl);
    await pump(tester, engine: engine, theme: AppTheme.dark);
    await tester.pumpAndSettle();
    expect(engine.spec!.styleUrl, MapConfig.darkStyleUrl);
  });

  testWidgets('markers take their colours from the theme', (tester) async {
    final engine = FakeMapEngine();
    await pump(
      tester,
      engine: engine,
      markers: const [
        MapMarker(id: 'pickup', point: _pickup, kind: MapMarkerKind.pickup),
        MapMarker(id: 'dropoff', point: _dropoff, kind: MapMarkerKind.dropoff),
        MapMarker(id: 'rider', point: _rider, kind: MapMarkerKind.rider),
      ],
    );
    final c = AppTheme.light.extension<AppColors>()!;
    expect(engine.marker('pickup')!.fill, c.forest500);
    expect(engine.marker('dropoff')!.fill, c.brand500);
    expect(engine.marker('rider')!.fill, c.ride500);
    expect(engine.marker('rider')!.point, _rider);
    for (final m in engine.markers) {
      expect(m.stroke, c.surfaceRaised);
      expect(m.fill, isNot(c.countdown));
    }
  });

  test('user agent names the app, version and platform', () {
    expect(
      MapConfig.userAgent(
        const ClientInfo(appVersion: '1.0.0+1', platform: 'android'),
      ),
      'RideLink/1.0.0+1 (android)',
    );
  });

  test('style URLs point at OpenFreeMap', () {
    expect(
      MapConfig.styleFor(Brightness.light),
      'https://tiles.openfreemap.org/styles/positron',
    );
    expect(
      MapConfig.styleFor(Brightness.dark),
      'https://tiles.openfreemap.org/styles/dark',
    );
  });
}
