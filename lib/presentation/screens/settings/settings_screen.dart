import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../profile/profile_selection_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Color(profile?.colorValue ?? 0xFF6750A4),
              child: Text(
                  (profile != null && profile.name.isNotEmpty)
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(profile?.name ?? 'Profil'),
            subtitle: const Text('Profil actif'),
            trailing: TextButton(
              onPressed: () {
                ref.read(activeProfileProvider.notifier).select(null);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const ProfileSelectionScreen()),
                );
              },
              child: const Text('Changer'),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Apparence',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Système'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Clair'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Sombre'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('À propos',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Otaku Tracker'),
            subtitle: Text(
                'Toutes les données (textes et images) restent stockées localement sur cet appareil. Aucune connexion Internet requise.'),
          ),
        ],
      ),
    );
  }
}
