/// A free-game giveaway (sourced from GamerPower).
class Giveaway {
  final int id;
  final String title;
  final String? worth; // e.g. "$4.99" or "N/A"
  final String? image;
  final String? thumbnail;
  final String description;
  final String url; // open_giveaway_url
  final String? type; // "Game", "DLC & Loot", "Early Access"
  final String? platforms;
  final String? endDate; // "YYYY-MM-DD HH:MM:SS" or "N/A"
  final String? users; // claimed count
  final String? status;

  const Giveaway({
    required this.id,
    required this.title,
    this.worth,
    this.image,
    this.thumbnail,
    required this.description,
    required this.url,
    this.type,
    this.platforms,
    this.endDate,
    this.users,
    this.status,
  });

  String get imageUrl => (image?.isNotEmpty ?? false)
      ? image!
      : (thumbnail ?? '');

  /// Whether the giveaway has a meaningful monetary value to highlight.
  bool get hasWorth =>
      worth != null && worth!.trim().isNotEmpty && worth!.toUpperCase() != 'N/A';

  String get endLabel {
    final e = endDate;
    if (e == null || e.trim().isEmpty || e.toUpperCase() == 'N/A') {
      return 'No end date';
    }
    return 'Ends $e';
  }

  factory Giveaway.fromJson(Map<String, dynamic> j) => Giveaway(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? 'Giveaway',
        worth: j['worth'] as String?,
        image: j['image'] as String?,
        thumbnail: j['thumbnail'] as String?,
        description: j['description'] as String? ?? '',
        url: j['open_giveaway_url'] as String? ??
            j['gamerpower_url'] as String? ??
            '',
        type: j['type'] as String?,
        platforms: j['platforms'] as String?,
        endDate: j['end_date'] as String?,
        users: j['users']?.toString(),
        status: j['status'] as String?,
      );
}
