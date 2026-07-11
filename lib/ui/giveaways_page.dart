import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/giveaway.dart';
import '../state/giveaways_state.dart';
import '../theme.dart';

class GiveawaysPage extends StatefulWidget {
  const GiveawaysPage({super.key});

  @override
  State<GiveawaysPage> createState() => _GiveawaysPageState();
}

class _GiveawaysPageState extends State<GiveawaysPage> {
  static const _platforms = {
    'steam': 'Steam',
    'epic-games-store': 'Epic',
    'gog': 'GOG',
    'pc': 'All PC',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiveawaysState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GiveawaysState>();
    return Column(
      children: [
        _platformBar(state),
        if (state.loadedOnce && state.items.isNotEmpty) _statsBar(state),
        Expanded(child: _body(state)),
      ],
    );
  }

  Widget _platformBar(GiveawaysState state) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _platforms.entries.map((e) {
          final selected = state.platform == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) => state.setPlatform(e.key),
              selectedColor: AppColors.accent,
              labelStyle: TextStyle(
                color: selected ? AppColors.bg : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.surface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statsBar(GiveawaysState state) {
    final worth = state.totalWorth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Text('${state.items.length} active',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          if (worth > 0)
            Text('~\$${worth.toStringAsFixed(2)} of games free',
                style: const TextStyle(
                    color: AppColors.low, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _body(GiveawaysState state) {
    if (state.loading && !state.loadedOnce) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (state.error != null && state.items.isEmpty) {
      return _message(state.error!, onRetry: () => state.load(force: true));
    }
    if (state.items.isEmpty) {
      return _message('No active giveaways for this platform right now.',
          onRetry: () => state.load(force: true));
    }
    return RefreshIndicator(
      onRefresh: () => state.load(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.items.length,
        itemBuilder: (_, i) => _GiveawayCard(state.items[i]),
      ),
    );
  }

  Widget _message(String text, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _GiveawayCard extends StatelessWidget {
  final Giveaway g;
  const _GiveawayCard(this.g);

  Future<void> _open() async {
    if (g.url.isEmpty) return;
    final uri = Uri.parse(g.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (g.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: g.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: AppColors.surfaceAlt),
                  errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white24)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (g.type != null) _badge(g.type!, AppColors.accent),
                      const SizedBox(width: 6),
                      const _FreeBadge('FREE', AppColors.sale),
                      const Spacer(),
                      if (g.hasWorth)
                        Text(
                          g.worth!,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(g.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(g.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(g.endLabel,
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      FilledButton.icon(
                        onPressed: _open,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sale,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.redeem, size: 16),
                        label: const Text('Claim'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _FreeBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _FreeBadge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}
