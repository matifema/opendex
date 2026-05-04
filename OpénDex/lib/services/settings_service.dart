import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _kGeminiApiKey = 'gemini_api_key';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get geminiApiKey {
    return _prefs.getString(_kGeminiApiKey) ?? '';
  }

  Future<void> setGeminiApiKey(String value) async {
    await _prefs.setString(_kGeminiApiKey, value);
  }
}
