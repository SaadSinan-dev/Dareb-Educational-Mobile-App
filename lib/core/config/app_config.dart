/// Public API configuration. Override per build with --dart-define=API_BASE_URL.
abstract final class AppConfig {
  /// Preview data is opt-in and is never enabled in a production release.
  static const demoMode =
      !bool.fromEnvironment('dart.vm.product') &&
      bool.fromEnvironment('APP_DEMO_MODE');

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://training.tamkeen-dev.com/dareb/public/api',
  );
}
