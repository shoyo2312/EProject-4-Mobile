class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// `--dart-define=USE_MOCK=true` runs the app off in-memory sample data
  /// instead of the backend. Off by default, release builds included.
  static const bool useMockData = bool.fromEnvironment('USE_MOCK');

  /// The **Web** OAuth client ID, not the Android or iOS one. Google puts the
  /// web client ID in the ID token's `aud` claim no matter which platform asked
  /// for it, and that is what auth-service checks against `GOOGLE_CLIENT_IDS`.
  /// Omitting it on Android yields a null `idToken` — the usual reason social
  /// login "fails on the backend" when the backend was never called.
  ///
  /// Public by design (it ships inside every app binary); the secret half of
  /// the pair never leaves auth-service.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '581480201411-pr5o1eeld820c30u2enb3nonbk68fihm.apps.googleusercontent.com',
  );
}
