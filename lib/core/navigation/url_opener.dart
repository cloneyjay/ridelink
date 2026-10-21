import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web or store link outside the app (Terms, Privacy, store page).
abstract class UrlOpener {
  /// False when the link is invalid or nothing could open it.
  Future<bool> open(String url);
}

class ExternalUrlOpener implements UrlOpener {
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => ExternalUrlOpener());
