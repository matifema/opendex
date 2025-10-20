const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// Sizes for generated pixel art (in px)
class PixelArtSize {
  static const int small = 128;
  static const int medium = 256;
  static const int large = 512;
}
