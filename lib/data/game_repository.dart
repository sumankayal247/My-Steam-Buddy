import 'dart:async';

import '../models/game.dart';
import 'disk_cache.dart';
import 'itad_api.dart';
import 'steam_api.dart';
import 'studios.dart';

typedef ProgressCallback = void Function(String message);

/// One fetched batch of the all-time-low Browse feed.
class AllTimeLowPage {
  /// Games from this batch that are flagged all-time-low (H) or a fresh
  /// record (N). Usually fewer than the raw batch size since most deals
  /// aren't at their historical low.
  final List<Game> games;

  /// Offset to pass in for the next batch.
  final int nextOffset;

  /// True once the underlying deals feed has no more pages.
  final bool exhausted;

  const AllTimeLowPage({required this.games, required this.nextOffset, required this.exhausted});
}

/// Builds the merged catalog (Steam popularity + ITAD pricing) and powers
/// the Studios page. Handles caching and throttled per-game title enrichment.
class GameRepository {
  final SteamApi steam;
  final ItadApi itad;
  final DiskCache cache;

  GameRepository({required this.steam, required this.itad, DiskCache? cache})
      : cache = cache ?? DiskCache();

  static const _catalogKey = 'catalog';
  static const _infoKey = 'info_cache';
  static const _catalogTtl = Duration(hours: 3);
  static const _infoTtl = Duration(days: 7);

  // In-memory + on-disk cache of ITAD per-game info (title/art/devs).
  final Map<String, ItadInfo> _infoMem = {};
  bool _infoLoaded = false;

  Future<void> _loadInfoCache() async {
    if (_infoLoaded) return;
    final raw = await cache.read(_infoKey, _infoTtl);
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          _infoMem[k as String] = ItadInfo(
            title: v['title'] as String? ?? 'Unknown',
            boxart: v['boxart'] as String?,
            developers:
                (v['developers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
            publishers:
                (v['publishers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          );
        }
      });
    }
    _infoLoaded = true;
  }

  Future<void> _saveInfoCache() async {
    await cache.write(_infoKey, {
      for (final e in _infoMem.entries)
        e.key: {
          'title': e.value.title,
          'boxart': e.value.boxart,
          'developers': e.value.developers,
          'publishers': e.value.publishers,
        }
    });
  }

  /// Build (or load cached) catalog of popular games enriched with prices.
  Future<List<Game>> loadCatalog({
    bool force = false,
    ProgressCallback? onProgress,
  }) async {
    if (!force) {
      final cached = await cache.read(_catalogKey, _catalogTtl);
      if (cached is List && cached.isNotEmpty) {
        return cached
            .whereType<Map>()
            .map((m) => Game.fromJson(m.cast<String, dynamic>()))
            .toList();
      }
    }

    onProgress?.call('Fetching most-played games…');
    final ranks = await steam.getMostPlayed();
    final appIds = ranks.map((r) => r.appId).toList();
    final rankByApp = {for (final r in ranks) r.appId: r};

    onProgress?.call('Matching games on IsThereAnyDeal…');
    final idByApp = await itad.lookupSteamAppIds(appIds);
    final appByItad = {for (final e in idByApp.entries) e.value: e.key};
    final ids = idByApp.values.toList();
    if (ids.isEmpty) return [];

    onProgress?.call('Loading prices…');
    final prices = await itad.steamPrices(ids);

    onProgress?.call('Loading price history…');
    final lows = await itad.historyLows(ids);

    onProgress?.call('Loading game details…');
    final infos = await _enrichInfo(ids, onProgress: onProgress);

    final games = <Game>[];
    for (final id in ids) {
      final appId = appByItad[id];
      final rank = appId != null ? rankByApp[appId] : null;
      final p = prices[id];
      final low = lows[id];
      final info = infos[id];
      games.add(Game(
        itadId: id,
        steamAppId: appId,
        title: info?.title ?? (appId != null ? 'Steam App $appId' : 'Unknown'),
        boxart: info?.boxart,
        price: p?.price,
        regular: p?.regular,
        cut: p?.cut ?? 0,
        currency: itad.country == 'IN' ? 'INR' : 'USD',
        shopName: p?.shopName,
        dealUrl: p?.url,
        lowestPrice: low?.price,
        lowestCut: low?.cut,
        steamRank: rank?.rank,
        peakPlayers: rank?.peakInGame,
        developers: info?.developers ?? const [],
        publishers: info?.publishers ?? const [],
      ));
    }

    // Default ordering: popularity (most-played rank ascending).
    games.sort((a, b) => (a.steamRank ?? 1 << 30).compareTo(b.steamRank ?? 1 << 30));

    await cache.write(_catalogKey, games.map((g) => g.toJson()).toList());
    return games;
  }

  /// Resolve titles/art/devs for a set of ITAD ids, using the on-disk info
  /// cache and fetching only what's missing (throttled concurrency).
  Future<Map<String, ItadInfo>> _enrichInfo(
    List<String> ids, {
    ProgressCallback? onProgress,
  }) async {
    await _loadInfoCache();
    final missing = ids.where((id) => !_infoMem.containsKey(id)).toList();
    var done = 0;
    await _runLimited<String>(missing, 8, (id) async {
      try {
        final info = await itad.info(id);
        if (info != null) _infoMem[id] = info;
      } catch (_) {
        // Skip games we can't enrich; they fall back to a placeholder title.
      }
      done++;
      if (done % 10 == 0) {
        onProgress?.call('Loading game details… $done/${missing.length}');
      }
    });
    if (missing.isNotEmpty) await _saveInfoCache();
    return {for (final id in ids) if (_infoMem[id] != null) id: _infoMem[id]!};
  }

  /// Games for a single studio (curated appids -> ITAD -> prices + details).
  Future<List<Game>> loadStudioGames(Studio studio) async {
    final key = 'studio_${studio.name.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}';
    final cached = await cache.read(key, _catalogTtl);
    if (cached is List && cached.isNotEmpty) {
      return cached
          .whereType<Map>()
          .map((m) => Game.fromJson(m.cast<String, dynamic>()))
          .toList();
    }

    final idByApp = await itad.lookupSteamAppIds(studio.appIds);
    final appByItad = {for (final e in idByApp.entries) e.value: e.key};
    final ids = idByApp.values.toList();
    if (ids.isEmpty) return [];

    final prices = await itad.steamPrices(ids);
    final lows = await itad.historyLows(ids);
    final infos = await _enrichInfo(ids);

    final games = <Game>[];
    for (final id in ids) {
      final appId = appByItad[id];
      final p = prices[id];
      final info = infos[id];
      final low = lows[id];
      games.add(Game(
        itadId: id,
        steamAppId: appId,
        title: info?.title ?? (appId != null ? 'Steam App $appId' : 'Unknown'),
        boxart: info?.boxart,
        price: p?.price,
        regular: p?.regular,
        cut: p?.cut ?? 0,
        currency: itad.country == 'IN' ? 'INR' : 'USD',
        shopName: p?.shopName,
        dealUrl: p?.url,
        lowestPrice: low?.price,
        lowestCut: low?.cut,
        developers: info?.developers ?? const [],
        publishers: info?.publishers ?? const [],
      ));
    }
    // Keep curated order, but float on-sale items to the top.
    games.sort((a, b) => b.cut.compareTo(a.cut));
    await cache.write(key, games.map((g) => g.toJson()).toList());
    return games;
  }

  /// One page of the Browse feed: Steam deals currently at their all-time
  /// low (or a freshly-broken record), sourced straight from ITAD's global
  /// deals feed rather than the ~100-game Steam most-played list. [offset]/
  /// [limit] page the *raw* deals feed — most raw rows won't be all-time
  /// lows, so [AllTimeLowPage.games] is usually shorter than [limit].
  static const int allTimeLowPageSize = 50;

  Future<AllTimeLowPage> loadAllTimeLowPage({
    required int offset,
    int limit = allTimeLowPageSize,
  }) async {
    final raw = await itad.deals(offset: offset, limit: limit, sort: '-cut');
    final games = raw.where((d) => d.isAllTimeLow).map(_gameFromDeal).toList();
    return AllTimeLowPage(
      games: games,
      nextOffset: offset + raw.length,
      exhausted: raw.length < limit,
    );
  }

  Game _gameFromDeal(ItadDeal d) => Game(
        itadId: d.id,
        steamAppId: _steamAppIdFromUrl(d.url),
        title: d.title,
        boxart: d.boxart,
        price: d.price,
        regular: d.regular,
        cut: d.cut,
        currency: itad.country == 'IN' ? 'INR' : 'USD',
        dealUrl: d.url,
        lowestPrice: d.historyLow ?? d.storeLow,
        isNewLow: d.isNewRecord,
      );

  static int? _steamAppIdFromUrl(String? url) {
    if (url == null) return null;
    final m = RegExp(r'/app/(\d+)').firstMatch(url);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  /// Global title search (beyond the loaded catalog) enriched with prices.
  Future<List<Game>> searchGames(String query) async {
    final hits = await itad.search(query, results: 20);
    if (hits.isEmpty) return [];
    final ids = hits.map((h) => h.id).toList();
    final prices = await itad.steamPrices(ids);
    final lows = await itad.historyLows(ids);
    return hits.map((h) {
      final p = prices[h.id];
      final low = lows[h.id];
      return Game(
        itadId: h.id,
        title: h.title,
        boxart: h.boxart,
        price: p?.price,
        regular: p?.regular,
        cut: p?.cut ?? 0,
        currency: itad.country == 'IN' ? 'INR' : 'USD',
        shopName: p?.shopName,
        dealUrl: p?.url,
        lowestPrice: low?.price,
        lowestCut: low?.cut,
      );
    }).toList();
  }

  Future<void> clearCache() async {
    await cache.clear(_catalogKey);
    for (final s in kStudios) {
      await cache
          .clear('studio_${s.name.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}');
    }
  }

  /// Run [task] over [items] with at most [concurrency] in flight.
  Future<void> _runLimited<T>(
    List<T> items,
    int concurrency,
    Future<void> Function(T) task,
  ) async {
    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= items.length) break;
        await task(items[i]);
      }
    }

    final workers = List.generate(
        concurrency < items.length ? concurrency : items.length, (_) => worker());
    await Future.wait(workers);
  }
}
