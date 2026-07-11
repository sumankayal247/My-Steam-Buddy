import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON cache with a TTL, backed by shared_preferences so it works
/// identically on Android and web (localStorage there, a plist/file
/// elsewhere) without touching dart:io directly.
class DiskCache {
  static const _prefix = 'disk_cache_';

  /// Returns the decoded payload if the cache exists and is younger than [ttl].
  Future<dynamic> read(String name, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$name');
      if (raw == null) return null;
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = wrapper['savedAt'] as int? ?? 0;
      final ageMs = _nowMs() - savedAt;
      if (ageMs > ttl.inMilliseconds) return null;
      return wrapper['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String name, Object data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_prefix$name', jsonEncode({'savedAt': _nowMs(), 'data': data}));
    } catch (_) {
      // Caching is best-effort; ignore failures.
    }
  }

  Future<void> clear(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$name');
    } catch (_) {}
  }

  // Wall clock is fine here (cache freshness), unlike in workflow scripts.
  int _nowMs() => DateTime.now().millisecondsSinceEpoch;
}
