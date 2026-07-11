import 'package:flutter_test/flutter_test.dart';

import 'package:mysteambuddy/models/game.dart';

void main() {
  test('discount and historical-low flags', () {
    const onSale = Game(
      itadId: 'x',
      title: 'Test',
      price: 300,
      regular: 1000,
      cut: 70,
      lowestPrice: 300,
    );
    expect(onSale.isOnSale, true);
    expect(onSale.isAtHistoricalLow, true);

    const full = Game(itadId: 'y', title: 'Full', price: 1000, regular: 1000, cut: 0);
    expect(full.isOnSale, false);
  });

  test('Game JSON round-trips', () {
    const g = Game(
      itadId: 'abc',
      steamAppId: 730,
      title: 'CS2',
      price: 0,
      cut: 0,
      steamRank: 1,
    );
    final back = Game.fromJson(g.toJson());
    expect(back.title, 'CS2');
    expect(back.steamAppId, 730);
    expect(back.steamRank, 1);
  });
}
