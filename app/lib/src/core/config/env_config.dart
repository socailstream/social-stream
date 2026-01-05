import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration helper
class EnvConfig {
  /// Ngrok base URL for API calls
  static String get ngrokBaseUrl => dotenv.env['NGROK_BASE_URL'] ?? 'http://localhost:5000';

  /// Gemini API key for AI features
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Check if running in production mode
  static bool get isProduction => ngrokBaseUrl.contains('ngrok');

  /// Initialize environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }
}
