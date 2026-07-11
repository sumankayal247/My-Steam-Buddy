/// A single game in the MySteamBuddy catalog.
///
/// Data is merged from two sources:
///  - Steam (`GetMostPlayedGames`) for popularity ranking + the appid.
///  - IsThereAnyDeal (ITAD) for current price, discount, and historical low.
class Game {
  final String itadId;
  final int? steamAppId;
  final String title;

  /// Current best price (in the selected country's currency, major units e.g. ₹1799.0).
  final double? price;

  /// Regular / non-discounted price.
  final double? regular;

  /// Current discount percentage (0-100).
  final int cut;

  final String currency;

  /// Shop offering the current price (e.g. "Steam").
  final String? shopName;

  /// Deep link to the deal / store page.
  final String? dealUrl;

  /// Lowest price ever recorded by ITAD.
  final double? lowestPrice;
  final int? lowestCut;

  /// Number of bundles the game is/was part of (ITAD `bundled`).
  final int bundledCount;

  /// Popularity from Steam most-played (1 = most played). Null if not ranked.
  final int? steamRank;
  final int? peakPlayers;

  final List<String> developers;
  final List<String> publishers;

  /// Explicit box-art URL (from ITAD) used when no Steam appid is available.
  final String? boxart;

  /// True when ITAD flagged this deal as a freshly-broken all-time-low
  /// record (as opposed to one that's been sitting at its low for a while).
  final bool isNewLow;

  const Game({
    required this.itadId,
    required this.title,
    this.steamAppId,
    this.boxart,
    this.price,
    this.regular,
    this.cut = 0,
    this.currency = 'INR',
    this.shopName,
    this.dealUrl,
    this.lowestPrice,
    this.lowestCut,
    this.bundledCount = 0,
    this.steamRank,
    this.peakPlayers,
    this.developers = const [],
    this.publishers = const [],
    this.isNewLow = false,
  });

  bool get isFree => (price ?? 0) == 0 && cut == 0 && regular == null;
  bool get isOnSale => cut > 0;

  /// True when the current price matches (or beats) the all-time lowest.
  bool get isAtHistoricalLow =>
      price != null && lowestPrice != null && price! <= lowestPrice! + 0.001;

  /// Cover image. Prefers the deterministic Steam CDN header (no API call),
  /// falling back to ITAD box art when there's no appid (e.g. search results).
  String? get imageUrl => steamAppId != null
      ? 'https://cdn.cloudflare.steamstatic.com/steam/apps/$steamAppId/header.jpg'
      : boxart;

  String? get steamUrl =>
      steamAppId == null ? null : 'https://store.steampowered.com/app/$steamAppId';

  Game copyWith({
    String? title,
    String? boxart,
    double? price,
    double? regular,
    int? cut,
    String? currency,
    String? shopName,
    String? dealUrl,
    double? lowestPrice,
    int? lowestCut,
    int? bundledCount,
    int? steamRank,
    int? peakPlayers,
    List<String>? developers,
    List<String>? publishers,
    bool? isNewLow,
  }) {
    return Game(
      itadId: itadId,
      steamAppId: steamAppId,
      title: title ?? this.title,
      boxart: boxart ?? this.boxart,
      price: price ?? this.price,
      regular: regular ?? this.regular,
      cut: cut ?? this.cut,
      currency: currency ?? this.currency,
      shopName: shopName ?? this.shopName,
      dealUrl: dealUrl ?? this.dealUrl,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      lowestCut: lowestCut ?? this.lowestCut,
      bundledCount: bundledCount ?? this.bundledCount,
      steamRank: steamRank ?? this.steamRank,
      peakPlayers: peakPlayers ?? this.peakPlayers,
      developers: developers ?? this.developers,
      publishers: publishers ?? this.publishers,
      isNewLow: isNewLow ?? this.isNewLow,
    );
  }

  Map<String, dynamic> toJson() => {
        'itadId': itadId,
        'steamAppId': steamAppId,
        'title': title,
        'boxart': boxart,
        'price': price,
        'regular': regular,
        'cut': cut,
        'currency': currency,
        'shopName': shopName,
        'dealUrl': dealUrl,
        'lowestPrice': lowestPrice,
        'lowestCut': lowestCut,
        'bundledCount': bundledCount,
        'steamRank': steamRank,
        'peakPlayers': peakPlayers,
        'developers': developers,
        'publishers': publishers,
        'isNewLow': isNewLow,
      };

  factory Game.fromJson(Map<String, dynamic> j) => Game(
        itadId: j['itadId'] as String,
        steamAppId: j['steamAppId'] as int?,
        title: j['title'] as String? ?? 'Unknown',
        boxart: j['boxart'] as String?,
        price: (j['price'] as num?)?.toDouble(),
        regular: (j['regular'] as num?)?.toDouble(),
        cut: (j['cut'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'INR',
        shopName: j['shopName'] as String?,
        dealUrl: j['dealUrl'] as String?,
        lowestPrice: (j['lowestPrice'] as num?)?.toDouble(),
        lowestCut: (j['lowestCut'] as num?)?.toInt(),
        bundledCount: (j['bundledCount'] as num?)?.toInt() ?? 0,
        steamRank: (j['steamRank'] as num?)?.toInt(),
        peakPlayers: (j['peakPlayers'] as num?)?.toInt(),
        developers:
            (j['developers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        publishers:
            (j['publishers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isNewLow: j['isNewLow'] as bool? ?? false,
      );
}
