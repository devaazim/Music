/// App-wide configuration. Verify these against the current Audius docs
/// (https://docs.audius.org) before shipping.
class AppConfig {
  static const appName = 'Tunely'; // rename your app here and in pubspec/manifests
  static const audiusBaseUrl = 'https://api.audius.co/v1';

  /// Optional: if Audius requires/offers an API key for your app, put it here.
  /// Never commit real secrets; pass with --dart-define=AUDIUS_API_KEY=xxx
  static const audiusApiKey = String.fromEnvironment('AUDIUS_API_KEY');
}
