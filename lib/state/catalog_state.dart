import 'package:flutter/material.dart';

import '../data/disk_cache.dart';
import '../data/game_repository.dart';
import '../data/itad_api.dart';
import '../data/steam_api.dart';
import '../models/game.dart';

enum SortMode { asFetched, priceLowHigh, priceHighToLow, newRecordFirst, name }

extension SortModeLabel on SortMode {
  String get label => switch (this) {
        SortMode.asFetched => 'Biggest discount',
        SortMode.priceLowHigh => 'Price: Low → High',
        SortMode.priceHighToLow => 'Price: High → Low',
        SortMode.newRecordFirst => 'New record lows first',
        SortMode.name => 'Name (A–Z)',
      };
}

/// Owns the Browse feed — Steam deals currently at their all-time low (or a
/// freshly-broken record) — as an incrementally-loaded, infinitely-scrolled
/// list, plus all client-side filtering/sorting on top of it.
class CatalogState extends ChangeNotifier {
  GameRepository? _repo;

  List<Game> _all = [];
  final Set<String> _seenIds = {};
  int _offset = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _progress = '';

  // Filters
  String _query = '';
  double _priceCeiling = 5000; // upper bound of the price slider (₹)
  RangeValues _priceRange = const RangeValues(0, 5000);
  int _minDiscount = 0;
  SortMode _sort = SortMode.asFetched;

  // Getters
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get progress => _progress;
  bool get hasData => _all.isNotEmpty;
  String get query => _query;
  double get priceCeiling => _priceCeiling;
  RangeValues get priceRange => _priceRange;
  int get minDiscount => _minDiscount;
  SortMode get sort => _sort;

  bool get isFiltering =>
      _query.isNotEmpty ||
      _minDiscount > 0 ||
      _priceRange.start > 0 ||
      _priceRange.end < _priceCeiling;

  /// (Re)build the repository when settings change.
  void configure({required String apiKey, required String country}) {
    _repo = GameRepository(
      steam: SteamApi(),
      itad: ItadApi(apiKey: apiKey, country: country),
      cache: DiskCache(),
    );
  }

  /// (Re)start the feed from the top.
  Future<void> load({bool force = false}) async {
    if (_repo == null) {
      _error = 'No API key configured.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    _progress = 'Finding all-time-low deals…';
    _all = [];
    _seenIds.clear();
    _offset = 0;
    _hasMore = true;
    notifyListeners();
    try {
      await _fetchMore(minNew: 20, maxRawPages: 6);
      _recomputePriceCeiling();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch the next batch for infinite scroll. Safe to call repeatedly
  /// (e.g. from scroll listeners) — no-ops while already loading.
  Future<void> loadMore() async {
    if (_repo == null || _loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      await _fetchMore(minNew: 15, maxRawPages: 6);
      _recomputePriceCeiling();
    } catch (e) {
      _error ??= e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Pull raw deal pages from ITAD until at least [minNew] new all-time-low
  /// games are gathered, the feed is exhausted, or [maxRawPages] is hit
  /// (most raw rows aren't all-time lows, so several pages are often needed
  /// to fill one screen).
  Future<void> _fetchMore({required int minNew, required int maxRawPages}) async {
    var gathered = 0;
    var pages = 0;
    while (_hasMore && gathered < minNew && pages < maxRawPages) {
      final page = await _repo!.loadAllTimeLowPage(offset: _offset);
      _offset = page.nextOffset;
      _hasMore = !page.exhausted;
      for (final g in page.games) {
        if (_seenIds.add(g.itadId)) {
          _all.add(g);
          gathered++;
        }
      }
      pages++;
      _progress = 'Found ${_all.length} all-time-low deals…';
      notifyListeners();
    }
  }

  void _recomputePriceCeiling() {
    double max = 0;
    for (final g in _all) {
      final p = g.regular ?? g.price ?? 0;
      if (p > max) max = p;
    }
    // Round up to a clean slider bound.
    _priceCeiling = max <= 0 ? 5000 : (((max / 500).ceil()) * 500).toDouble();
    _priceRange = RangeValues(0, _priceCeiling);
  }

  // ---- Filter setters ----
  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setPriceRange(RangeValues r) {
    _priceRange = r;
    notifyListeners();
  }

  void setMinDiscount(int d) {
    _minDiscount = d;
    notifyListeners();
  }

  void setSort(SortMode s) {
    _sort = s;
    notifyListeners();
  }

  void resetFilters() {
    _query = '';
    _minDiscount = 0;
    _priceRange = RangeValues(0, _priceCeiling);
    _sort = SortMode.asFetched;
    notifyListeners();
  }

  GameRepository? get repo => _repo;

  /// The filtered + sorted list shown in the UI.
  List<Game> get visibleGames {
    final q = _query.trim().toLowerCase();
    final list = _all.where((g) {
      if (q.isNotEmpty && !g.title.toLowerCase().contains(q)) return false;
      if (g.cut < _minDiscount) return false;
      final price = g.price ?? 0;
      // Free games (price 0) only pass when the lower bound is 0.
      if (price < _priceRange.start || price > _priceRange.end) return false;
      return true;
    }).toList();

    switch (_sort) {
      case SortMode.asFetched:
        break; // server already returns deals sorted by biggest discount.
      case SortMode.priceLowHigh:
        list.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case SortMode.priceHighToLow:
        list.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      case SortMode.newRecordFirst:
        list.sort((a, b) {
          if (a.isNewLow != b.isNewLow) return a.isNewLow ? -1 : 1;
          return b.cut.compareTo(a.cut);
        });
      case SortMode.name:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }
}
