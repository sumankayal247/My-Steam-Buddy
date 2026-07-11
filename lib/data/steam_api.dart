import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// One entry from Steam's live "most played" chart.
class SteamRank {
  final int appId;
  final int rank;
  final int peakInGame;
  const SteamRank(this.appId, this.rank, this.peakInGame);
}

/// Thin client for the few public Steam endpoints we need.
/// Only used for the popularity ranking — prices come from ITAD.
class SteamApi {
  final http.Client _http;
  SteamApi([http.Client? client]) : _http = client ?? http.Client();

  // Browsers can't call api.steampowered.com directly (no CORS headers), so
  // the web build routes through a CORS proxy: tool/web_proxy.py locally, or
  // a deployed Cloudflare Worker in production (see cloudflare-worker/),
  // pointed to via --dart-define=PROXY_BASE=... at build time.
  static const _proxyBase =
      String.fromEnvironment('PROXY_BASE', defaultValue: 'http://127.0.0.1:8787');
  static String get _mostPlayed => kIsWeb
      ? '$_proxyBase/steam/ISteamChartsService/GetMostPlayedGames/v1/'
      : 'https://api.steampowered.com/ISteamChartsService/GetMostPlayedGames/v1/';

  /// Live most-played games (Steam caps this at ~100), ranked by current players.
  Future<List<SteamRank>> getMostPlayed() async {
    final res = await _http
        .get(Uri.parse(_mostPlayed))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Steam most-played failed: HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final ranks = (body['response']?['ranks'] as List?) ?? const [];
    return ranks
        .map((e) => SteamRank(
              (e['appid'] as num).toInt(),
              (e['rank'] as num).toInt(),
              (e['peak_in_game'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  void close() => _http.close();
}
