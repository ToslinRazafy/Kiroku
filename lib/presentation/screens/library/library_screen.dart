import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../providers/providers.dart';
import '../../widgets/content_card.dart';
import '../content/add_edit_content_screen.dart';
import '../content/content_detail_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final filter = ref.watch(libraryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma bibliothèque'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditContentScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un titre...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => ref
                  .read(libraryFilterProvider.notifier)
                  .update((f) => f.copyWith(query: value)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _TypeFilterChip(type: null, label: 'Tous'),
                for (final type in ContentType.values)
                  _TypeFilterChip(type: type, label: type.label),
                const SizedBox(width: 8),
                VerticalDivider(width: 1, indent: 6, endIndent: 6),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filtres'),
                  onPressed: () => _openFilterSheet(context, ref),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: Text(filter.sortMode.label),
                  onPressed: () => _openSortSheet(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: libraryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun contenu ne correspond à ces filtres.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ContentCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ContentDetailScreen(itemId: item.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => const _FilterSheet(),
    );
  }

  void _openSortSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: SortMode.values
            .map((mode) => ListTile(
                  title: Text(mode.label),
                  onTap: () {
                    ref
                        .read(libraryFilterProvider.notifier)
                        .update((f) => f.copyWith(sortMode: mode));
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _TypeFilterChip extends ConsumerWidget {
  final ContentType? type;
  final String label;
  const _TypeFilterChip({required this.type, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);
    final selected = filter.type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(libraryFilterProvider.notifier).update(
              (f) => type == null
                  ? f.copyWith(clearType: true)
                  : f.copyWith(type: type),
            ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon statut', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: filter.personalStatus == null,
                onSelected: (_) => ref
                    .read(libraryFilterProvider.notifier)
                    .update((f) => f.copyWith(clearPersonalStatus: true)),
              ),
              for (final status in PersonalStatus.values)
                FilterChip(
                  label: Text(status.labelFor(filter.type ?? ContentType.anime)),
                  selected: filter.personalStatus == status,
                  onSelected: (_) => ref
                      .read(libraryFilterProvider.notifier)
                      .update((f) => f.copyWith(personalStatus: status)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Genre', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: filter.genre == null,
                onSelected: (_) => ref
                    .read(libraryFilterProvider.notifier)
                    .update((f) => f.copyWith(clearGenre: true)),
              ),
              for (final genre in kDefaultGenres)
                FilterChip(
                  label: Text(genre),
                  selected: filter.genre == genre,
                  onSelected: (_) => ref
                      .read(libraryFilterProvider.notifier)
                      .update((f) => f.copyWith(genre: genre)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ref.read(libraryFilterProvider.notifier).reset();
                Navigator.pop(context);
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ),
        ],
      ),
    );
  }
}
