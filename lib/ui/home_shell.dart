import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/settings_state.dart';
import '../theme.dart';
import 'browse_page.dart';
import 'giveaways_page.dart';
import 'monitor_page.dart';
import 'settings_page.dart';
import 'studios_page.dart';

class HomeShell extends StatefulWidget {
  /// True when no API key was found at launch — opens straight on Settings
  /// and prompts the user to add their free ITAD key.
  final bool startOnSettings;

  const HomeShell({super.key, this.startOnSettings = false});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _settingsIndex = 4;
  late int _index = widget.startOnSettings ? _settingsIndex : 0;

  static const _titles = [
    'MySteamBuddy',
    'Popular Studios',
    'Monitor Games',
    'Giveaways',
    'Settings'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.startOnSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeDialog());
    }
  }

  Future<void> _showWelcomeDialog() async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Welcome to MySteamBuddy'),
        content: const Text(
          'To load live prices and deals, add a free IsThereAnyDeal API key below. '
          'It takes under a minute to create one.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://isthereanydeal.com/apps/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Get free API key'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Got it', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final pages = [
      const BrowsePage(),
      const StudiosPage(),
      const MonitorPage(),
      const GiveawaysPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_esports, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text(_titles[_index],
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!settings.hasKey && _index != 4) _keyBanner(),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Studios'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Monitor'),
          BottomNavigationBarItem(icon: Icon(Icons.redeem), label: 'Giveaways'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _keyBanner() {
    return Material(
      color: AppColors.surfaceAlt,
      child: InkWell(
        onTap: () => setState(() => _index = _settingsIndex),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.key, color: AppColors.low, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add your free IsThereAnyDeal API key to load prices →',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
