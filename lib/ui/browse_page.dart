import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/catalog_state.dart';
import '../theme.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/game_tile.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<CatalogState>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogState>();
    return Column(
      children: [
        _searchBar(context, cat),
        Expanded(child: _body(context, cat)),
      ],
    );
  }

  Widget _searchBar(BuildContext context, CatalogState cat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: cat.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search games…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton.filledTonal(
                onPressed: () => FilterSheet.show(context),
                icon: const Icon(Icons.tune),
                style: IconButton.styleFrom(backgroundColor: AppColors.surface),
              ),
              if (cat.isFiltering)
                const Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CatalogState cat) {
    if (cat.loading && !cat.hasData) {
      return _loading(cat.progress);
    }
    if (cat.error != null && !cat.hasData) {
      return _error(context, cat);
    }
    final games = cat.visibleGames;
    if (games.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => cat.load(force: true),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No games match your filters.', style: TextStyle(color: Colors.white54))),
          ],
        ),
      );
    }
    final showFooter = cat.hasMore || cat.loadingMore;
    return RefreshIndicator(
      onRefresh: () => cat.load(force: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Text('${games.length} all-time-low deals',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Text('Sorted by ${cat.sort.label}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: games.length + (showFooter ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= games.length) return _footer();
                return GameTile(game: games[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _loading(String progress) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(progress.isEmpty ? 'Loading…' : progress,
              style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, CatalogState cat) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.white30),
            const SizedBox(height: 12),
            Text(cat.error ?? 'Something went wrong',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => cat.load(force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
