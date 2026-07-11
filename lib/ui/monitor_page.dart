import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../state/catalog_state.dart';
import '../state/monitor_state.dart';
import '../theme.dart';
import 'widgets/game_tile.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  String? _searchError;
  List<Game> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    if (_query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), _runSearch);
  }

  Future<void> _runSearch() async {
    final repo = context.read<CatalogState>().repo;
    if (repo == null) {
      setState(() => _searchError = 'Add your ITAD API key in Settings first.');
      return;
    }
    final q = _query;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final res = await repo.searchGames(q);
      if (mounted && q == _query) setState(() => _results = res);
    } catch (e) {
      if (mounted) setState(() => _searchError = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _searchBar(),
        Expanded(child: _query.isEmpty ? _monitoredList() : _searchResults()),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search any game to monitor…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    _onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _monitoredList() {
    final monitor = context.watch<MonitorState>();
    if (monitor.isEmpty) {
      return _emptyState();
    }
    final repo = context.read<CatalogState>().repo;
    return RefreshIndicator(
      onRefresh: () async {
        if (repo != null) await monitor.refresh(repo);
      },
      child: Column(
        children: [
          if (monitor.refreshing) const LinearProgressIndicator(color: AppColors.accent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Text('${monitor.games.length} monitored',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                const Text('Pull to refresh prices',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children:
                  monitor.games.map((g) => GameTile(game: g, monitorToggle: true)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_searchError!,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('No results for “$_query”.',
            style: const TextStyle(color: Colors.white54)),
      );
    }
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text('Tap the star to monitor a game',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        ..._results.map((g) => GameTile(game: g, monitorToggle: true)),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bookmark_added_outlined, size: 56, color: Colors.white24),
            SizedBox(height: 16),
            Text('No games monitored yet',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(
              'Search above to find any game and tap the ⭐ to add it here. '
              'You can also star games from the Browse and Studios tabs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
