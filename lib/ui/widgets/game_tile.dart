import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/game.dart';
import '../../state/monitor_state.dart';
import '../../theme.dart';

/// A horizontal card showing a game's art, title, price, discount and badges.
class GameTile extends StatelessWidget {
  final Game game;

  /// When true, shows a star to add/remove the game from the watchlist.
  final bool monitorToggle;

  const GameTile({super.key, required this.game, this.monitorToggle = true});

  Future<void> _open() async {
    final url = game.dealUrl ?? game.steamUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _cover(),
              ),
              const SizedBox(width: 12),
              Expanded(child: _details(context)),
              if (monitorToggle) _monitorStar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    const w = 120.0, h = 56.0;
    final url = game.imageUrl;
    if (url == null) {
      return Container(
        width: w,
        height: h,
        color: AppColors.surfaceAlt,
        child: const Icon(Icons.videogame_asset, color: Colors.white24),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: w,
      height: h,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          Container(width: w, height: h, color: AppColors.surfaceAlt),
      errorWidget: (context, url, error) => Container(
        width: w,
        height: h,
        color: AppColors.surfaceAlt,
        child: const Icon(Icons.videogame_asset, color: Colors.white24),
      ),
    );
  }

  Widget _monitorStar(BuildContext context) {
    final monitor = context.watch<MonitorState>();
    final on = monitor.isMonitored(game.itadId);
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: on ? 'Stop monitoring' : 'Monitor this game',
      icon: Icon(
        on ? Icons.star : Icons.star_border,
        color: on ? AppColors.low : Colors.white38,
      ),
      onPressed: () async {
        await monitor.toggle(game);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(on
                  ? 'Removed “${game.title}” from Monitor'
                  : 'Now monitoring “${game.title}”'),
            ),
          );
        }
      },
    );
  }

  Widget _details(BuildContext context) {
    final g = game;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          g.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Row(children: [
          if (g.steamRank != null) ...[
            const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
            Text(' #${g.steamRank}  ', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
          if (g.peakPlayers != null && g.peakPlayers! > 0) ...[
            const Icon(Icons.people, size: 13, color: Colors.white38),
            Text(' ${formatPlayers(g.peakPlayers)}', style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ]),
        const SizedBox(height: 8),
        _priceRow(),
        if (g.isAtHistoricalLow || (g.lowestPrice != null))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _lowBadge(),
          ),
      ],
    );
  }

  Widget _priceRow() {
    final g = game;
    if (g.price == null) {
      return const Text('Price unavailable', style: TextStyle(color: Colors.white38, fontSize: 13));
    }
    return Row(children: [
      if (g.cut > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.sale,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('-${g.cut}%',
              style: const TextStyle(color: AppColors.saleText, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      if (g.cut > 0) const SizedBox(width: 8),
      if (g.cut > 0 && g.regular != null)
        Text(
          formatPrice(g.regular, g.currency),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      if (g.cut > 0 && g.regular != null) const SizedBox(width: 6),
      Text(
        formatPrice(g.price, g.currency),
        style: TextStyle(
          color: g.cut > 0 ? AppColors.saleText : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ]);
  }

  Widget _lowBadge() {
    final g = game;
    if (g.isNewLow) {
      return Row(children: const [
        Icon(Icons.new_releases, size: 14, color: AppColors.saleText),
        SizedBox(width: 4),
        Text('New record low!',
            style: TextStyle(color: AppColors.saleText, fontSize: 12, fontWeight: FontWeight.w600)),
      ]);
    }
    if (g.isAtHistoricalLow) {
      return Row(children: const [
        Icon(Icons.trending_down, size: 14, color: AppColors.low),
        SizedBox(width: 4),
        Text('All-time low!', style: TextStyle(color: AppColors.low, fontSize: 12, fontWeight: FontWeight.w600)),
      ]);
    }
    return Text(
      'Lowest ever: ${formatPrice(g.lowestPrice, g.currency)}',
      style: const TextStyle(color: Colors.white38, fontSize: 11),
    );
  }
}
