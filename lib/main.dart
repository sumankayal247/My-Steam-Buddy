import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/catalog_state.dart';
import 'state/giveaways_state.dart';
import 'state/monitor_state.dart';
import 'state/settings_state.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

void main() {
  runApp(const MySteamBuddyApp());
}

class MySteamBuddyApp extends StatelessWidget {
  const MySteamBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => CatalogState()),
        ChangeNotifierProvider(create: (_) => MonitorState()),
        ChangeNotifierProvider(create: (_) => GiveawaysState()),
      ],
      child: MaterialApp(
        title: 'MySteamBuddy',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Bootstrap(),
      ),
    );
  }
}

/// Loads persisted settings, then configures + loads the catalog if a key exists.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;
  bool _startOnSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final settings = context.read<SettingsState>();
    final catalog = context.read<CatalogState>();
    final monitor = context.read<MonitorState>();
    await settings.load();
    await monitor.load();
    if (mounted) {
      setState(() {
        _startOnSettings = !settings.hasKey;
        _ready = true;
      });
    }
    if (settings.hasKey) {
      catalog.configure(apiKey: settings.apiKey, country: settings.country);
      await catalog.load();
      final repo = catalog.repo;
      if (repo != null) await monitor.refresh(repo);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    return HomeShell(startOnSettings: _startOnSettings);
  }
}
