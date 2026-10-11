/// Server location, set at build time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   (Android emulator, default)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080  (iOS simulator)
class AppConfig {
  AppConfig({required Uri apiBaseUrl})
    : apiBaseUrl = apiBaseUrl.replace(path: _trimSlash(apiBaseUrl.path));

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: defaultApiBaseUrl,
      ),
    ),
  );

  static const defaultApiBaseUrl = 'http://10.0.2.2:8080';

  final Uri apiBaseUrl;

  /// Base for every REST call; all API paths live under /v1.
  String get apiV1 => '${apiBaseUrl.toString()}/v1/';

  Uri get webSocketUri => apiBaseUrl.replace(
    scheme: apiBaseUrl.scheme == 'https' ? 'wss' : 'ws',
    path: '${apiBaseUrl.path}/v1/ws',
  );

  static String _trimSlash(String path) =>
      path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}
