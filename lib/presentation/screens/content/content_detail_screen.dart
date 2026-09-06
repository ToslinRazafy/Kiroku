import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/media_item.dart';
import '../../../data/models/season.dart';
import '../../providers/providers.dart';
import '../../widgets/progress_bar.dart';
import 'add_edit_content_screen.dart';

final _itemDetailProvider =
    FutureProvider.family<MediaItem?, String>((ref, id) async {
  ref.watch(libraryRevisionProvider);
  return ref.read(mediaRepositoryProvider).getById(id);
});

class ContentDetailScreen extends ConsumerWidget {
  final String itemId;
  const ContentDetailScreen({super.key, required this.itemId});

  Future<void> _adjustProgress(WidgetRef ref, MediaItem item, int delta) async {
    final repo = ref.read(mediaRepositoryProvider);
    MediaItem updated;

    if (item.type == ContentType.anime) {
      final upperBound = item.totalEpisodes ?? item.airedEpisodes ?? (1 << 30);
      final next = (item.currentEpisode + delta).clamp(0, upperBound).toInt();
      updated = item.copyWith(currentEpisode: next);
      if (item.totalEpisodes != null && next == item.totalEpisodes && delta > 0) {
        updated = updated.copyWith(personalStatus: PersonalStatus.completed);
      }
    } else {
      final upperBound = item.totalChapters ?? item.publishedChapters ?? (1 << 30);
      final next = (item.currentChapter + delta).clamp(0, upperBound).toInt();
      updated = item.copyWith(currentChapter: next);
      if (item.totalChapters != null && next == item.totalChapters && delta > 0) {
        updated = updated.copyWith(personalStatus: PersonalStatus.completed);
      }
    }
    await repo.update(updated);
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _setExactProgress(
      BuildContext context, WidgetRef ref, MediaItem item) async {
    final isAnime = item.type == ContentType.anime;
    final controller = TextEditingController(
      text: (isAnime ? item.currentEpisode : item.currentChapter).toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAnime ? 'Épisode actuel' : 'Chapitre actuel'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final repo = ref.read(mediaRepositoryProvider);
    final updated = isAnime
        ? item.copyWith(currentEpisode: value.clamp(0, 1 << 30).toInt())
        : item.copyWith(currentChapter: value.clamp(0, 1 << 30).toInt());
    await repo.update(updated);
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _changePersonalStatus(
      BuildContext context, WidgetRef ref, MediaItem item) async {
    final choice = await showModalBottomSheet<PersonalStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Mon statut',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            for (final status in PersonalStatus.values)
              ListTile(
                title: Text(status.labelFor(item.type)),
                trailing: item.personalStatus == status
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final repo = ref.read(mediaRepositoryProvider);
    await repo.update(item.copyWith(personalStatus: choice));
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _changeWorkStatus(
      BuildContext context, WidgetRef ref, MediaItem item) async {
    final choice = await showModalBottomSheet<PublicationStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Statut réel de l\u2019œuvre',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            for (final status in PublicationStatus.values)
              ListTile(
                title: Text(status.label),
                trailing: item.workStatus == status
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final repo = ref.read(mediaRepositoryProvider);
    await repo.update(item.copyWith(workStatus: choice));
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _changeWatchLanguage(
      BuildContext context, WidgetRef ref, MediaItem item) async {
    final choice = await showModalBottomSheet<WatchLanguage>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Langue de visionnage',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            for (final lang in WatchLanguage.values)
              ListTile(
                title: Text(lang.label),
                trailing: item.watchLanguage == lang
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, lang),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final repo = ref.read(mediaRepositoryProvider);
    await repo.update(item.copyWith(watchLanguage: choice));
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _pickSeason(
      BuildContext context, WidgetRef ref, MediaItem item) async {
    final seasons = await ref.read(seasonsProvider(item.id).future);
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SeasonSheet(item: item, seasons: seasons),
    );
    if (choice == null) return;
    final repo = ref.read(mediaRepositoryProvider);
    if (choice is Season) {
      await repo.update(item.copyWith(currentSeason: choice.seasonNumber));
    } else if (choice == _addSeasonSentinel) {
      final nextNumber = (seasons.isEmpty
              ? 0
              : seasons.map((s) => s.seasonNumber).reduce((a, b) => a > b ? a : b)) +
          1;
      await repo.createSeason(Season(
        id: '',
        mediaItemId: item.id,
        seasonNumber: nextNumber,
      ));
    }
    ref.read(libraryRevisionProvider.notifier).state++;
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voulez-vous vraiment supprimer cet élément ?'),
        content: Text(item.title),
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
      await ref.read(mediaRepositoryProvider).delete(item.id);
      ref.read(libraryRevisionProvider.notifier).state++;
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(_itemDetailProvider(itemId));

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Contenu introuvable.'));
          }
          return _DetailBody(
            item: item,
            onAdjust: (d) => _adjustProgress(ref, item, d),
            onEditProgress: () => _setExactProgress(context, ref, item),
            onEditPersonalStatus: () => _changePersonalStatus(context, ref, item),
            onEditWorkStatus: () => _changeWorkStatus(context, ref, item),
            onEditWatchLanguage: () => _changeWatchLanguage(context, ref, item),
            onEditSeason: () => _pickSeason(context, ref, item),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditContentScreen(existing: item)),
            ),
            onDelete: () => _confirmDelete(context, ref, item),
          );
        },
      ),
    );
  }
}

const _addSeasonSentinel = '__add_season__';

class _SeasonSheet extends ConsumerWidget {
  final MediaItem item;
  final List<Season> seasons;
  const _SeasonSheet({required this.item, required this.seasons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saisons', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (seasons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucune saison enregistrée pour le moment.'),
              ),
            for (final season in seasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text('S${season.seasonNumber}'),
                ),
                title: Text(season.title?.isNotEmpty == true
                    ? season.title!
                    : 'Saison ${season.seasonNumber}'),
                subtitle: Text(
                  [
                    season.status.label,
                    if (season.availableEpisodes != null || season.totalEpisodes != null)
                      'Épisodes : ${season.availableEpisodes ?? '?'} / ${season.totalEpisodes ?? '?'}',
                  ].join(' · '),
                ),
                trailing: item.currentSeason == season.seasonNumber
                    ? const Icon(Icons.check_circle)
                    : null,
                onTap: () => Navigator.pop(context, season),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, _addSeasonSentinel),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une saison'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final MediaItem item;
  final void Function(int delta) onAdjust;
  final VoidCallback onEditProgress;
  final VoidCallback onEditPersonalStatus;
  final VoidCallback onEditWorkStatus;
  final VoidCallback onEditWatchLanguage;
  final VoidCallback onEditSeason;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailBody({
    required this.item,
    required this.onAdjust,
    required this.onEditProgress,
    required this.onEditPersonalStatus,
    required this.onEditWorkStatus,
    required this.onEditWatchLanguage,
    required this.onEditSeason,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: item.coverImagePath != null ? 260 : 120,
          pinned: true,
          actions: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(item.title, overflow: TextOverflow.ellipsis),
            background: item.coverImagePath != null
                ? Image.file(File(item.coverImagePath!), fit: BoxFit.cover)
                : Container(color: scheme.surfaceContainerHigh),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (item.originalTitle != null && item.originalTitle!.isNotEmpty) ...[
                Text(
                  item.originalTitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, color: scheme.outline),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text(item.type.label)),
                  // Statut réel de l'œuvre : tap pour le mettre à jour.
                  ActionChip(
                    avatar: const Icon(Icons.public, size: 16),
                    label: Text('Œuvre : ${item.workStatus.label}'),
                    onPressed: onEditWorkStatus,
                  ),
                  // Statut personnel : tap pour le changer rapidement.
                  ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(
                        'Moi : ${item.personalStatus.labelFor(item.type)}'),
                    onPressed: onEditPersonalStatus,
                  ),
                  if (item.type == ContentType.anime)
                    ActionChip(
                      avatar: const Icon(Icons.subtitles_outlined, size: 16),
                      label: Text(item.watchLanguage?.label ?? 'Langue ?'),
                      onPressed: onEditWatchLanguage,
                    ),
                  if (item.rating != null)
                    Chip(
                      avatar: const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      label: Text(item.rating!.toStringAsFixed(1)),
                    ),
                ],
              ),
              if (item.isCaughtUpButOngoing) ...[
                const SizedBox(height: 8),
                Text(
                  "À jour : vous avez vu/lu tout ce qui est disponible, mais l'œuvre continue.",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.outline),
                ),
              ],
              const SizedBox(height: 16),

              AppProgressBar(progress: item.progress, label: item.progressLabel),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => onAdjust(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onEditProgress,
                    child: Text(
                      item.type == ContentType.anime
                          ? '${item.currentEpisode}'
                          : '${item.currentChapter}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    onPressed: () => onAdjust(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (item.type == ContentType.anime) ...[
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: onEditSeason,
                    icon: const Icon(Icons.video_library_outlined, size: 18),
                    label: Text(item.currentSeason != null
                        ? 'Saison ${item.currentSeason}'
                        : 'Choisir la saison'),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              if (item.description != null && item.description!.isNotEmpty) ...[
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(item.description!),
                const SizedBox(height: 16),
              ],

              if (item.genres.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      item.genres.map((g) => Chip(label: Text(g))).toList(),
                ),
                const SizedBox(height: 16),
              ],

              _InfoGrid(item: item, dateFormat: dateFormat),

              if (item.comment != null && item.comment!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Commentaire personnel',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(item.comment!),
              ],
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final MediaItem item;
  final DateFormat dateFormat;
  const _InfoGrid({required this.item, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[];

    if (item.type == ContentType.anime) {
      if (item.currentSeason != null || item.totalSeasons != null) {
        rows.add(MapEntry('Saison',
            '${item.currentSeason ?? '?'} / ${item.totalSeasons ?? '?'}'));
      }
      if (item.airedEpisodes != null) {
        rows.add(MapEntry('Épisodes diffusés', item.airedEpisodes.toString()));
      }
      if (item.studio != null) rows.add(MapEntry('Studio', item.studio!));
      if (item.releaseYear != null) {
        rows.add(MapEntry('Année', item.releaseYear.toString()));
      }
      if (item.hasSequel != null) {
        rows.add(MapEntry('Suite prévue', item.hasSequel! ? 'Oui' : 'Non'));
      }
    } else {
      if (item.author != null) rows.add(MapEntry('Auteur', item.author!));
      if (item.type == ContentType.manga &&
          (item.currentVolume > 0 || item.totalVolumes != null)) {
        rows.add(MapEntry(
            'Tome', '${item.currentVolume} / ${item.totalVolumes ?? '?'}'));
      }
      if (item.publishedChapters != null) {
        rows.add(MapEntry('Chapitres publiés', item.publishedChapters.toString()));
      }
      if (item.currentArcName != null) {
        rows.add(MapEntry('Arc actuel', item.currentArcName!));
      }
    }
    if (item.startDate != null) {
      rows.add(MapEntry('Début', dateFormat.format(item.startDate!)));
    }
    if (item.endDate != null) {
      rows.add(MapEntry('Fin', dateFormat.format(item.endDate!)));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: rows
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                        Text(e.value,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
