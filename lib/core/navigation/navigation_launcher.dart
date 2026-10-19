import 'package:url_launcher/url_launcher.dart';

import '../location/geo_point.dart';

/// Turn-by-turn hand-off to the Google Maps app (frontend decision 13): an app intent, not a
/// data call. Tried in order: the navigation intent, a geo: URI, then the Maps web link.
List<Uri> navigationUris(GeoPoint p) {
  final at = '${p.lat},${p.lng}';
  return [
    Uri.parse('google.navigation:q=$at'),
    Uri.parse('geo:$at?q=$at'),
    Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': at}),
  ];
}

abstract class NavigationLauncher {
  /// False when no app could open any of the URIs.
  Future<bool> navigateTo(GeoPoint destination);
}

/// Opens a URI in another app; returns false when nothing handled it.
typedef UriOpener = Future<bool> Function(Uri uri);

class UrlNavigationLauncher implements NavigationLauncher {
  UrlNavigationLauncher({UriOpener? open}) : _open = open ?? _launchExternal;

  final UriOpener _open;

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<bool> navigateTo(GeoPoint destination) async {
    for (final uri in navigationUris(destination)) {
      try {
        if (await _open(uri)) return true;
      } catch (_) {
        // No handler for this scheme; try the next one.
      }
    }
    return false;
  }
}
