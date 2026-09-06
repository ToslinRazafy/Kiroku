import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/content_card.dart';
import '../content/add_edit_content_screen.dart';
import '../content/content_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final statsAsync = ref.watch(statsProvider);
    final continueAsync = ref.watch(continueWatchingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Salut, ${profile?.name ?? ''} 👋'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditContentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(libraryRevisionProvider.notifier).state++;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              loading: () => const SizedBox(
                  height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Erreur : $e'),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _StatTile(
                      icon: Icons.movie_outlined,
                      label: 'Animes',
                      value: stats.totalAnime.toString()),
                  _StatTile(
                      icon: Icons.menu_book_outlined,
                      label: 'Mangas',
                      value: stats.totalManga.toString()),
                  _StatTile(
                      icon: Icons.auto_stories_outlined,
                      label: 'Manhwas',
                      value: stats.totalManhwa.toString()),
                  _StatTile(
                      icon: Icons.play_circle_outline,
                      label: 'En cours',
                      value: stats.inProgress.toString()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Continuer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            continueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur : $e'),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyContinue();
                }
                return Column(
                  children: items
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ContentCard(
                              item: item,
                              onTap: () => _openDetail(context, item),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContentDetailScreen(itemId: item.id)),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContinue extends StatelessWidget {
  const _EmptyContinue();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.local_fire_department_outlined,
                size: 32, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            const Text('Rien en cours pour le moment.'),
            const Text('Ajoute un anime, manga ou manhwa pour commencer !'),
          ],
        ),
      ),
    );
  }
}
