import 'package:flutter/material.dart';

import '../data/studios.dart';
import '../theme.dart';
import 'studio_detail_page.dart';

class StudiosPage extends StatelessWidget {
  const StudiosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: kStudios.length,
      itemBuilder: (_, i) {
        final s = kStudios[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceAlt,
              child: Text(s.name.characters.first,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.tagline, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudioDetailPage(studio: s)),
            ),
          ),
        );
      },
    );
  }
}
