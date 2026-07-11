import 'package:flutter/foundation.dart';

import '../data/giveaways_api.dart';
import '../models/giveaway.dart';

class GiveawaysState extends ChangeNotifier {
  final GiveawaysApi _api;
  GiveawaysState({GiveawaysApi? api}) : _api = api ?? GiveawaysApi();

  List<Giveaway> _items = [];
  bool _loading = false;
  String? _error;
  String _platform = 'steam';
  bool _loadedOnce = false;

  List<Giveaway> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  String get platform => _platform;
  bool get loadedOnce => _loadedOnce;

  /// Total worth of all active giveaways, for a nice header stat.
  double get totalWorth {
    var sum = 0.0;
    for (final g in _items) {
      final w = g.worth;
      if (w == null) continue;
      final cleaned = w.replaceAll(RegExp(r'[^0-9.]'), '');
      final v = double.tryParse(cleaned);
      if (v != null) sum += v;
    }
    return sum;
  }

  Future<void> setPlatform(String platform) async {
    if (_platform == platform) return;
    _platform = platform;
    await load(force: true);
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loadedOnce && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.giveaways(platform: _platform);
      _loadedOnce = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
