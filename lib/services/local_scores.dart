import 'package:shared_preferences/shared_preferences.dart';

class LocalScores {
  static const _kPrefix = 'max_puntuazioa__';

  static Future<int?> getHighScore(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_kPrefix$username');
  }

  static Future<void> setHighScore(String username, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kPrefix$username', value);
  }

  static Future<void> clearFor(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPrefix$username');
  }
}