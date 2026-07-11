import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/studios.dart';
import '../models/game.dart';
import '../state/catalog_state.dart';
import '../theme.dart';
import 'widgets/game_tile.dart';

class StudioDetailPage extends StatefulWidget {
  final Studio studio;
  const StudioDetailPage({super.key, required this.studio});

  @override
  State<StudioDetailPage> createState() => _StudioDetailPageState();
}

class _StudioDetailPageState extends State<StudioDetailPage> {
  List<Game>? _games;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<CatalogState>().repo;
    if (repo == null) {
      setState(() => _error = 'No API key configured.');
      return;
    }
    try {
      final games = await repo.loadStudioGames(widget.studio);
      if (mounted) setState(() => _games = games);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _games;
    final onSale = games?.where((g) => g.isOnSale).toList() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studio.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.studio.tagline,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ),
      ),
      body: _body(games, onSale),
    );
  }

  Widget _body(List<Game>? games, List<Game> onSale) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
        ),
      );
    }
    if (games == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (games.isEmpty) {
      return const Center(
        child: Text('Couldn’t load this studio’s games.', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView(
      children: [
        if (onSale.isNotEmpty) ...[
          _sectionHeader('🔥 On sale now (${onSale.length})', AppColors.sale),
          ...onSale.map((g) => GameTile(game: g)),
          _sectionHeader('All games', Colors.white70),
        ],
        ...games.map((g) => GameTile(game: g)),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Studio line-ups are curated. Prices & discounts are live from IsThereAnyDeal.',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
