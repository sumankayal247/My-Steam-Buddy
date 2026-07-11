import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_repository.dart';
import '../models/game.dart';

/// User's monitored games (watchlist), persisted across launches.
class MonitorState extends ChangeNotifier {
  static const _kKey = 'monitored_games';

  final List<Game> _games = [];
  bool _refreshing = false;

  List<Game> get games => List.unmodifiable(_games);
  bool get refreshing => _refreshing;
  bool get isEmpty => _games.isEmpty;

  bool isMonitored(String itadId) => _games.any((g) => g.itadId == itadId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _games
        ..clear()
        ..addAll(list.whereType<Map>().map((m) => Game.fromJson(m.cast<String, dynamic>())));
      notifyListeners();
    } catch (_) {
      // Corrupt store; start fresh.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(_games.map((g) => g.toJson()).toList()));
  }

  Future<void> add(Game game) async {
    if (isMonitored(game.itadId)) return;
    _games.add(game);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String itadId) async {
    _games.removeWhere((g) => g.itadId == itadId);
    notifyListeners();
    await _persist();
  }

  Future<void> toggle(Game game) async {
    if (isMonitored(game.itadId)) {
      await remove(game.itadId);
    } else {
      await add(game);
    }
  }

  /// Re-fetch live prices + history for every monitored game.
  Future<void> refresh(GameRepository repo) async {
    if (_games.isEmpty || _refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      final ids = _games.map((g) => g.itadId).toList();
      final prices = await repo.itad.steamPrices(ids);
      final lows = await repo.itad.historyLows(ids);
      for (var i = 0; i < _games.length; i++) {
        final g = _games[i];
        final p = prices[g.itadId];
        final low = lows[g.itadId];
        _games[i] = g.copyWith(
          price: p?.price,
          regular: p?.regular,
          cut: p?.cut,
          shopName: p?.shopName,
          dealUrl: p?.url,
          lowestPrice: low?.price,
          lowestCut: low?.cut,
        );
      }
      await _persist();
    } catch (_) {
      // Keep last-known prices on failure.
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }
}
