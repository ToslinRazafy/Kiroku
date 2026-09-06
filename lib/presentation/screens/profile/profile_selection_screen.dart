import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile.dart';
import '../../providers/providers.dart';

const List<int> kProfileColors = [
  0xFF6750A4, 0xFFB4436C, 0xFF386641, 0xFF1D4E89,
  0xFFBF6900, 0xFF7C3AED, 0xFF057A66, 0xFFAA3939,
];

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  Future<void> _createProfileDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    int selectedColor = kProfileColors.first;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kProfileColors.map((c) {
                  final selected = c == selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: CircleAvatar(
                      radius: selected ? 18 : 15,
                      backgroundColor: Color(c),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (created == true && controller.text.trim().isNotEmpty) {
      final profile = await ref
          .read(profilesProvider.notifier)
          .createProfile(controller.text.trim(), selectedColor);
      ref.read(activeProfileProvider.notifier).select(profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_rounded, size: 64),
                const SizedBox(height: 12),
                Text('Otaku Tracker',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Qui regarde / qui lit ?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                profilesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Erreur : $e'),
                  data: (profiles) {
                    if (profiles.isEmpty) {
                      return Text(
                        'Aucun profil pour le moment.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: profiles
                          .map((p) => _ProfileTile(profile: p))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  onPressed: () => _createProfileDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  final Profile profile;
  const _ProfileTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ref.read(activeProfileProvider.notifier).select(profile),
      onLongPress: () => _confirmDelete(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Color(profile.colorValue),
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 90,
              child: Text(
                profile.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text(
          'Toute la bibliothèque de "${profile.name}" sera supprimée définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profilesProvider.notifier).deleteProfile(profile.id);
    }
  }
}
