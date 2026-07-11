/// A curated game studio / publisher with representative Steam appids.
///
/// Steam has no public "all games by publisher" API, so the Studios page is
/// powered by hand-picked appids. Each appid is resolved live through ITAD;
/// any id that can't be resolved is simply skipped, so a stale entry just
/// disappears rather than breaking the page.
class Studio {
  final String name;
  final String tagline;
  final List<int> appIds;
  const Studio(this.name, this.tagline, this.appIds);
}

const List<Studio> kStudios = [
  Studio('Valve', 'Half-Life · Portal · Counter-Strike', [
    730, // Counter-Strike 2
    570, // Dota 2
    440, // Team Fortress 2
    620, // Portal 2
    400, // Portal
    220, // Half-Life 2
    546560, // Half-Life: Alyx
    550, // Left 4 Dead 2
    70, // Half-Life
  ]),
  Studio('Rockstar Games', 'GTA · Red Dead Redemption', [
    271590, // GTA V
    1174180, // Red Dead Redemption 2
    1404210, // Red Dead Redemption
    204100, // Max Payne 3
    110800, // L.A. Noire
    12120, // GTA San Andreas
    12210, // GTA IV
  ]),
  Studio('Bethesda', 'Elder Scrolls · Fallout · DOOM', [
    489830, // Skyrim Special Edition
    377160, // Fallout 4
    22380, // Fallout: New Vegas
    1716740, // Starfield
    782330, // DOOM Eternal
    379720, // DOOM (2016)
    403640, // Dishonored 2
    480490, // Prey
    612880, // Wolfenstein II
    306130, // The Elder Scrolls Online
  ]),
  Studio('CD PROJEKT RED', 'The Witcher · Cyberpunk 2077', [
    292030, // The Witcher 3: Wild Hunt
    1091500, // Cyberpunk 2077
    20920, // The Witcher 2
    20900, // The Witcher: Enhanced Edition
    1284410, // GWENT
  ]),
  Studio('FromSoftware', 'Dark Souls · Elden Ring · Sekiro', [
    1245620, // Elden Ring
    814380, // Sekiro
    374320, // Dark Souls III
    335300, // Dark Souls II: SotFS
    570940, // Dark Souls: Remastered
  ]),
  Studio('Capcom', 'Resident Evil · Monster Hunter · DMC', [
    582010, // Monster Hunter: World
    1446780, // Monster Hunter Rise
    2050650, // Resident Evil 4
    1196590, // Resident Evil Village
    883710, // Resident Evil 2
    601150, // Devil May Cry 5
    1364780, // Street Fighter 6
    2054970, // Dragon's Dogma 2
  ]),
  Studio('Ubisoft', "Assassin's Creed · Far Cry", [
    2208920, // AC Valhalla
    812140, // AC Odyssey
    582160, // AC Origins
    552520, // Far Cry 5
    359550, // Rainbow Six Siege
    447040, // Watch Dogs 2
    916440, // Anno 1800
  ]),
  Studio('Electronic Arts', 'Apex · The Sims · Battlefield', [
    1172470, // Apex Legends
    1222670, // The Sims 4
    1238810, // Battlefield V
    1237970, // Titanfall 2
    1426210, // It Takes Two
    1774580, // STAR WARS Jedi: Survivor
    1172380, // STAR WARS Jedi: Fallen Order
    1328670, // Mass Effect Legendary Edition
  ]),
  Studio('Square Enix', 'Final Fantasy · Tomb Raider · NieR', [
    1462040, // FFVII Remake Intergrade
    637650, // Final Fantasy XV
    524220, // NieR:Automata
    750920, // Shadow of the Tomb Raider
    391220, // Rise of the Tomb Raider
    203160, // Tomb Raider (2013)
  ]),
  Studio('Bandai Namco', 'Elden Ring (pub) · Tekken · Dark Souls', [
    1778820, // Tekken 8
    1903340, // Armored Core VI
    1888160, // Little Nightmares III? (placeholder; resolves or skips)
    1235140, // Yakuza? placeholder
  ]),
];
