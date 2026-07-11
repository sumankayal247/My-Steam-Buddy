import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings: the ITAD API key and the price region.
class SettingsState extends ChangeNotifier {
  static const _kKey = 'itad_api_key';
  static const _kCountry = 'country';

  String _apiKey = '';
  String _country = 'IN';
  bool _loaded = false;

  String get apiKey => _apiKey;
  String get country => _country;
  bool get loaded => _loaded;
  bool get hasKey => _apiKey.trim().isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_kKey) ?? '';
    _country = prefs.getString(_kCountry) ?? 'IN';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, _apiKey);
    notifyListeners();
  }

  Future<void> setCountry(String country) async {
    _country = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCountry, country);
    notifyListeners();
  }
}
