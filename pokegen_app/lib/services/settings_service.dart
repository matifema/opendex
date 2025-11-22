import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class SettingsService {
  static const String _kGeminiApiKey = 'gemini_api_key';
  static const String _kApiBaseUrl = 'api_base_url';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get geminiApiKey {
    final stored = _prefs.getString(_kGeminiApiKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return kGeminiApiKey;
  }

  Future<void> setGeminiApiKey(String value) async {
    await _prefs.setString(_kGeminiApiKey, value);
  }

  String get apiBaseUrl {
    final stored = _prefs.getString(_kApiBaseUrl);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return kApiBaseUrl;
  }

  Future<void> setApiBaseUrl(String value) async {
    await _prefs.setString(_kApiBaseUrl, value);
  }
}
