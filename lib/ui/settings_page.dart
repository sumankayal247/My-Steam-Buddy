import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/catalog_state.dart';
import '../state/settings_state.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _keyCtrl;
  late String _country;

  static const _countries = {
    'IN': 'India (₹)',
    'US': 'United States (\$)',
    'GB': 'United Kingdom (£)',
    'DE': 'Germany (€)',
    'CA': 'Canada (\$)',
    'AU': 'Australia (\$)',
  };

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsState>();
    _keyCtrl = TextEditingController(text: s.apiKey);
    _country = s.country;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = context.read<SettingsState>();
    final catalog = context.read<CatalogState>();
    await settings.setApiKey(_keyCtrl.text);
    await settings.setCountry(_country);
    if (settings.hasKey) {
      catalog.configure(apiKey: settings.apiKey, country: settings.country);
      await catalog.load(force: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved — refreshing catalog')),
        );
      }
    }
  }

  Future<void> _openItad() async {
    final uri = Uri.parse('https://isthereanydeal.com/apps/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('IsThereAnyDeal API key',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text(
          'MySteamBuddy uses IsThereAnyDeal for live prices and history. '
          'Create a free account, register an app to get a key, and paste it below.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _openItad,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Get a free API key'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keyCtrl,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Paste your ITAD API key',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _country,
              isExpanded: true,
              dropdownColor: AppColors.surfaceAlt,
              items: _countries.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _country = v ?? 'IN'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('Save & refresh',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final catalog = context.read<CatalogState>();
            await catalog.repo?.clearCache();
            await catalog.load(force: true);
          },
          child: const Text('Clear cache & reload'),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Popularity data from Steam. Prices & price history from IsThereAnyDeal. '
            'MySteamBuddy is not affiliated with Valve or ITAD.',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
