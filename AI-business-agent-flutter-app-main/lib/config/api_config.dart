/// External integration settings.
///
/// Replace the placeholder values at release time or pass them with
/// `--dart-define=BACKEND_URL=...` so secrets do not live in git.
class ApiConfig {
  // Node.js Backend URL
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    // This is the public Node.js service declared in the repository's
    // Render blueprint. Local development can override it with
    // --dart-define=BACKEND_URL=http://10.0.2.2:5000 (emulator) or a LAN IP.
    defaultValue: 'https://ai-business-agent-api.onrender.com',
  );

  static const baseUrl = String.fromEnvironment(
    'TOCHKA_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const aiApiKey = String.fromEnvironment('TOCHKA_AI_API_KEY');
  static const mapsProvider = String.fromEnvironment(
    'MAPS_PROVIDER',
    defaultValue: '2gis',
  );
  static const twoGisKey = String.fromEnvironment('TWOGIS_API_KEY');
  static const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'ai-agent-app-be146',
  );
  static const firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );
  static const appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
  static const appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://ai-business-agent-api.onrender.com/auth/apple/callback',
  );
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );
  static const posApiBaseUrl = String.fromEnvironment('POS_API_BASE_URL');
  static const posApiKey = String.fromEnvironment('POS_API_KEY');

  static bool get hasAiKey => aiApiKey.isNotEmpty;
  static bool get hasPaymentsKey => stripePublishableKey.isNotEmpty;
}
