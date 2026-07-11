import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/giveaway.dart';

class GiveawaysException implements Exception {
  final String message;
  GiveawaysException(this.message);
  @override
  String toString() => 'GiveawaysException: $message';
}

/// Client for the free, key-less GamerPower giveaways API.
class GiveawaysApi {
  final http.Client _http;
  GiveawaysApi({http.Client? client}) : _http = client ?? http.Client();

  static const _base = 'https://www.gamerpower.com/api';

  /// Active giveaways. [platform] e.g. 'steam', 'epic-games-store', 'pc'.
  /// [sortBy] one of 'value', 'date', 'popularity'.
  Future<List<Giveaway>> giveaways({
    String platform = 'steam',
    String sortBy = 'value',
  }) async {
    final uri = Uri.parse('$_base/giveaways').replace(queryParameters: {
      'platform': platform,
      'sort-by': sortBy,
    });
    final res = await _http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw GiveawaysException('HTTP ${res.statusCode} loading giveaways.');
    }
    final body = res.body.trim();
    if (body.isEmpty) return [];
    final data = jsonDecode(body);
    // API returns {"status":N} (an int) when there are no results.
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((m) => Giveaway.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  void close() => _http.close();
}
