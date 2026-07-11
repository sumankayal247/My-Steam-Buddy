import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Steam's shop id within IsThereAnyDeal.
const int kItadSteamShopId = 61;

class ItadPrice {
  final double? price;
  final double? regular;
  final int cut;
  final String? shopName;
  final String? url;
  const ItadPrice({this.price, this.regular, this.cut = 0, this.shopName, this.url});
}

class ItadLow {
  final double? price;
  final int? cut;
  const ItadLow({this.price, this.cut});
}

class ItadInfo {
  final String title;
  final String? boxart;
  final List<String> developers;
  final List<String> publishers;
  const ItadInfo({
    required this.title,
    this.boxart,
    this.developers = const [],
    this.publishers = const [],
  });
}

/// One row of the ITAD deals feed (already carries a title + art).
///
/// [flag] mirrors ITAD's deal badge: `H` = historical (all-time) low,
/// `N` = new historical low (record just broken), `S` = shop low, or null.
class ItadDeal {
  final String id;
  final String title;
  final String? boxart;

  /// Banner art fallback — DLC/package-type entries often have no [boxart]
  /// at all, only banners.
  final String? banner;
  final double? price;
  final double? regular;
  final int cut;
  final double? storeLow;
  final double? historyLow;
  final String? flag;
  final String? url;
  const ItadDeal({
    required this.id,
    required this.title,
    this.boxart,
    this.banner,
    this.price,
    this.regular,
    this.cut = 0,
    this.storeLow,
    this.historyLow,
    this.flag,
    this.url,
  });

  /// Best available cover image for a landscape tile: banner (matches the
  /// tile's aspect ratio) first, portrait boxart as a fallback for the rare
  /// entry with no banner at all.
  String? get coverImage => banner ?? boxart;

  /// All-time low or a freshly-broken record — the two flags this app
  /// treats as "all-time low" in Browse.
  bool get isAllTimeLow => flag == 'H' || flag == 'N';
  bool get isNewRecord => flag == 'N';
}

class ItadException implements Exception {
  final String message;
  ItadException(this.message);
  @override
  String toString() => 'ItadException: $message';
}

/// Client for the IsThereAnyDeal API v2. Requires a free API key
/// (register an app at https://isthereanydeal.com/apps/).
class ItadApi {
  final String apiKey;
  final String country;
  final http.Client _http;

  ItadApi({required this.apiKey, this.country = 'IN', http.Client? client})
      : _http = client ?? http.Client();

  // Browsers can't call api.isthereanydeal.com directly (no CORS headers), so
  // the web build routes through a CORS proxy: tool/web_proxy.py locally, or
  // a deployed Cloudflare Worker in production (see cloudflare-worker/),
  // pointed to via --dart-define=PROXY_BASE=... at build time.
  static const _proxyBase =
      String.fromEnvironment('PROXY_BASE', defaultValue: 'http://127.0.0.1:8787');
  static String get _base => kIsWeb ? '$_proxyBase/itad' : 'https://api.isthereanydeal.com';

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$_base$path').replace(
        queryParameters: {'key': apiKey, ...?q},
      );

  Future<dynamic> _post(Uri uri, Object body) async {
    final res = await _http
        .post(uri,
            headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ItadException('Invalid or missing ITAD API key.');
    }
    if (res.statusCode == 429) {
      throw ItadException('ITAD rate limit hit, try again shortly.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ItadException('HTTP ${res.statusCode} on ${uri.path}');
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  Future<dynamic> _get(Uri uri) async {
    final res = await _http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ItadException('Invalid or missing ITAD API key.');
    }
    if (res.statusCode == 429) {
      throw ItadException('ITAD rate limit hit, try again shortly.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ItadException('HTTP ${res.statusCode} on ${uri.path}');
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  static double? _amount(dynamic priceObj) {
    if (priceObj is Map) {
      final a = priceObj['amount'];
      if (a is num) return a.toDouble();
    }
    return null;
  }

  /// Map Steam appids -> ITAD game ids in one bulk call. Unknown apps are omitted.
  Future<Map<int, String>> lookupSteamAppIds(List<int> appIds) async {
    if (appIds.isEmpty) return {};
    final result = <int, String>{};
    // Chunk to stay friendly with payload sizes.
    for (final chunk in _chunks(appIds, 200)) {
      final body = chunk.map((id) => 'app/$id').toList();
      final data = await _post(_u('/lookup/id/shop/$kItadSteamShopId/v1'), body);
      if (data is Map) {
        data.forEach((k, v) {
          if (v is String && k is String && k.startsWith('app/')) {
            final appId = int.tryParse(k.substring(4));
            if (appId != null) result[appId] = v;
          }
        });
      }
    }
    return result;
  }

  /// Current Steam prices for a set of ITAD ids (bulk). Keyed by ITAD id.
  /// Only the Steam shop deal is kept so prices reflect Steam, not third parties.
  Future<Map<String, ItadPrice>> steamPrices(List<String> ids) async {
    final out = <String, ItadPrice>{};
    for (final chunk in _chunks(ids, 200)) {
      final data = await _post(
        _u('/games/prices/v3',
            {'country': country, 'shops': '$kItadSteamShopId', 'nondeals': 'true'}),
        chunk,
      );
      if (data is List) {
        for (final entry in data) {
          if (entry is! Map) continue;
          final id = entry['id'] as String?;
          if (id == null) continue;
          final deals = (entry['deals'] as List?) ?? const [];
          Map? steamDeal;
          for (final d in deals) {
            if (d is Map && (d['shop']?['id'] as num?)?.toInt() == kItadSteamShopId) {
              steamDeal = d;
              break;
            }
          }
          steamDeal ??= deals.isNotEmpty && deals.first is Map ? deals.first as Map : null;
          if (steamDeal == null) continue;
          out[id] = ItadPrice(
            price: _amount(steamDeal['price']),
            regular: _amount(steamDeal['regular']),
            cut: (steamDeal['cut'] as num?)?.toInt() ?? 0,
            shopName: steamDeal['shop']?['name'] as String?,
            url: steamDeal['url'] as String?,
          );
        }
      }
    }
    return out;
  }

  /// All-time lowest recorded price per ITAD id (bulk).
  Future<Map<String, ItadLow>> historyLows(List<String> ids) async {
    final out = <String, ItadLow>{};
    for (final chunk in _chunks(ids, 200)) {
      final data =
          await _post(_u('/games/historylow/v1', {'country': country}), chunk);
      if (data is List) {
        for (final entry in data) {
          if (entry is! Map) continue;
          final id = entry['id'] as String?;
          if (id == null) continue;
          final low = entry['low'] ?? entry; // tolerate either shape
          out[id] = ItadLow(
            price: _amount(low['price'] ?? low['amount']),
            cut: (low['cut'] as num?)?.toInt(),
          );
        }
      }
    }
    return out;
  }

  /// Per-game info: title, box art, developers, publishers. Single game only.
  Future<ItadInfo?> info(String id) async {
    final data = await _get(_u('/games/info/v2', {'id': id}));
    if (data is! Map) return null;
    final title = data['title'] as String?;
    if (title == null) return null;
    final assets = data['assets'];
    final boxart = assets is Map
        ? (assets['boxart'] ?? assets['banner600'] ?? assets['banner400']) as String?
        : null;
    List<String> names(dynamic v) => v is List
        ? v
            .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
            .where((s) => s.isNotEmpty)
            .toList()
        : const [];
    return ItadInfo(
      title: title,
      boxart: boxart,
      developers: names(data['developers']),
      publishers: names(data['publishers']),
    );
  }

  /// A page of the global deals feed (titles + art already included).
  Future<List<ItadDeal>> deals({
    int offset = 0,
    int limit = 50,
    String sort = '-cut',
  }) async {
    final data = await _get(_u('/deals/v2', {
      'country': country,
      'offset': '$offset',
      'limit': '$limit',
      'sort': sort,
      'shops': '$kItadSteamShopId',
    }));
    final list = data is Map ? (data['list'] as List?) : (data as List?);
    if (list == null) return [];
    return list.whereType<Map>().map((g) {
      final deal = g['deal'];
      final assets = g['assets'];
      return ItadDeal(
        id: g['id'] as String? ?? '',
        title: g['title'] as String? ?? 'Unknown',
        boxart: assets is Map ? assets['boxart'] as String? : null,
        banner: assets is Map
            ? (assets['banner300'] ?? assets['banner400'] ?? assets['banner600'] ?? assets['banner145'])
                as String?
            : null,
        price: deal is Map ? _amount(deal['price']) : null,
        regular: deal is Map ? _amount(deal['regular']) : null,
        cut: deal is Map ? (deal['cut'] as num?)?.toInt() ?? 0 : 0,
        storeLow: deal is Map ? _amount(deal['storeLow']) : null,
        historyLow: deal is Map ? _amount(deal['historyLow']) : null,
        flag: deal is Map ? deal['flag'] as String? : null,
        url: deal is Map ? deal['url'] as String? : null,
      );
    }).where((d) => d.id.isNotEmpty).toList();
  }

  /// Search games by title (used for global name search beyond the loaded set).
  Future<List<ItadDeal>> search(String title, {int results = 20}) async {
    final data =
        await _get(_u('/games/search/v1', {'title': title, 'results': '$results'}));
    final list = data is List ? data : (data is Map ? data['results'] as List? : null);
    if (list == null) return [];
    return list.whereType<Map>().map((g) {
      final assets = g['assets'];
      return ItadDeal(
        id: g['id'] as String? ?? '',
        title: g['title'] as String? ?? 'Unknown',
        boxart: assets is Map ? assets['boxart'] as String? : null,
      );
    }).where((d) => d.id.isNotEmpty).toList();
  }

  Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }

  void close() => _http.close();
}
