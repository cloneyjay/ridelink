/// Build-time settings:
///   --dart-define=API_BASE_URL=http://10.0.2.2:8080   (Android emulator, default)
///   --dart-define=API_BASE_URL=http://localhost:8080  (iOS simulator)
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_OAUTH_CLIENT_ID  (Google sign-in is hidden when absent)
class AppConfig {
  AppConfig({required Uri apiBaseUrl, String? googleServerClientId})
    : apiBaseUrl = apiBaseUrl.replace(path: _trimSlash(apiBaseUrl.path)),
      googleServerClientId =
          (googleServerClientId == null || googleServerClientId.isEmpty)
          ? null
          : googleServerClientId;

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: defaultApiBaseUrl,
      ),
    ),
    googleServerClientId: const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
  );

  static const defaultApiBaseUrl = 'http://10.0.2.2:8080';

  final Uri apiBaseUrl;

  /// Google's web OAuth client id; null until the founder configures Google Cloud.
  final String? googleServerClientId;

  /// Base for every REST call; all API paths live under /v1.
  String get apiV1 => '${apiBaseUrl.toString()}/v1/';

  Uri get webSocketUri => apiBaseUrl.replace(
    scheme: apiBaseUrl.scheme == 'https' ? 'wss' : 'ws',
    path: '${apiBaseUrl.path}/v1/ws',
  );

  static String _trimSlash(String path) =>
      path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}
