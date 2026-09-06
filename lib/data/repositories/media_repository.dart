import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../local/database_helper.dart';
import '../models/media_item.dart';
import '../models/season.dart';

/// Filtres combinables pour la bibliothèque.
class MediaFilter {
  final ContentType? type;
  final PersonalStatus? personalStatus;
  final String? genre;
  final String query;
  final SortMode sortMode;

  const MediaFilter({
    this.type,
    this.personalStatus,
    this.genre,
    this.query = '',
    this.sortMode = SortMode.lastModified,
  });

  MediaFilter copyWith({
    ContentType? type,
    bool clearType = false,
    PersonalStatus? personalStatus,
    bool clearPersonalStatus = false,
    String? genre,
    bool clearGenre = false,
    String? query,
    SortMode? sortMode,
  }) {
    return MediaFilter(
      type: clearType ? null : (type ?? this.type),
      personalStatus:
          clearPersonalStatus ? null : (personalStatus ?? this.personalStatus),
      genre: clearGenre ? null : (genre ?? this.genre),
      query: query ?? this.query,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

class LibraryStats {
  final int totalAnime;
  final int totalManga;
  final int totalManhwa;
  final int completed;
  final int inProgress;
  final int dropped;
  final int totalEpisodesWatched;
  final int totalChaptersRead;

  const LibraryStats({
    this.totalAnime = 0,
    this.totalManga = 0,
    this.totalManhwa = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.dropped = 0,
    this.totalEpisodesWatched = 0,
    this.totalChaptersRead = 0,
  });
}

class MediaRepository {
  final DatabaseHelper _dbHelper;
  static const _uuid = Uuid();

  MediaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<MediaItem> create(MediaItem draft) async {
    final db = await _dbHelper.database;
    final item = MediaItem(
      id: _uuid.v4(),
      profileId: draft.profileId,
      type: draft.type,
      title: draft.title,
      originalTitle: draft.originalTitle,
      coverImagePath: draft.coverImagePath,
      description: draft.description,
      workStatus: draft.workStatus,
      hasSequel: draft.hasSequel,
      personalStatus: draft.personalStatus,
      rating: draft.rating,
      comment: draft.comment,
      startDate: draft.startDate,
      endDate: draft.endDate,
      genres: draft.genres,
      totalEpisodes: draft.totalEpisodes,
      airedEpisodes: draft.airedEpisodes,
      currentEpisode: draft.currentEpisode,
      totalSeasons: draft.totalSeasons,
      currentSeason: draft.currentSeason,
      studio: draft.studio,
      releaseYear: draft.releaseYear,
      watchLanguage: draft.watchLanguage,
      totalVolumes: draft.totalVolumes,
      publishedVolumes: draft.publishedVolumes,
      currentVolume: draft.currentVolume,
      author: draft.author,
      totalChapters: draft.totalChapters,
      publishedChapters: draft.publishedChapters,
      currentChapter: draft.currentChapter,
      currentArcName: draft.currentArcName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.insert('media_items', item.toMap());
    return item;
  }

  Future<void> update(MediaItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      'media_items',
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('media_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<MediaItem?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('media_items', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MediaItem.fromMap(rows.first);
  }

  Future<List<MediaItem>> getForProfile(
    String profileId, {
    MediaFilter filter = const MediaFilter(),
  }) async {
    final db = await _dbHelper.database;

    final where = <String>['profileId = ?'];
    final args = <Object?>[profileId];

    if (filter.type != null) {
      where.add('type = ?');
      args.add(filter.type!.name);
    }
    if (filter.personalStatus != null) {
      where.add('personalStatus = ?');
      args.add(filter.personalStatus!.name);
    }
    if (filter.genre != null && filter.genre!.isNotEmpty) {
      where.add('genres LIKE ?');
      args.add('%${filter.genre}%');
    }
    if (filter.query.trim().isNotEmpty) {
      final q = '%${filter.query.trim().toLowerCase()}%';
      where.add('(LOWER(title) LIKE ? OR LOWER(originalTitle) LIKE ?)');
      args.add(q);
      args.add(q);
    }

    final orderBy = switch (filter.sortMode) {
      SortMode.nameAsc => 'LOWER(title) ASC',
      SortMode.nameDesc => 'LOWER(title) DESC',
      SortMode.lastModified => 'updatedAt DESC',
      SortMode.dateAdded => 'createdAt DESC',
      SortMode.rating => 'rating DESC',
      // La progression n'est pas une colonne SQL (calcul dérivé du type),
      // on trie donc après lecture, voir plus bas.
      SortMode.progression => 'updatedAt DESC',
    };

    final rows = await db.query(
      'media_items',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
    );

    var items = rows.map(MediaItem.fromMap).toList();

    if (filter.sortMode == SortMode.progression) {
      items.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return items;
  }

  /// Contenus "en cours" (statut personnel), triés par dernière mise à
  /// jour, pour la section "Continuer" de l'accueil.
  Future<List<MediaItem>> getContinueWatching(String profileId,
      {int limit = 5}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'media_items',
      where: 'profileId = ? AND personalStatus = ?',
      whereArgs: [profileId, PersonalStatus.inProgress.name],
      orderBy: 'updatedAt DESC',
      limit: limit,
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<LibraryStats> getStats(String profileId) async {
    final items = await getForProfile(profileId);

    int totalAnime = 0, totalManga = 0, totalManhwa = 0;
    int completed = 0, inProgress = 0, dropped = 0;
    int episodesWatched = 0, chaptersRead = 0;

    for (final item in items) {
      switch (item.type) {
        case ContentType.anime:
          totalAnime++;
          episodesWatched += item.currentEpisode;
          break;
        case ContentType.manga:
          totalManga++;
          chaptersRead += item.currentChapter;
          break;
        case ContentType.manhwa:
          totalManhwa++;
          chaptersRead += item.currentChapter;
          break;
      }
      switch (item.personalStatus) {
        case PersonalStatus.completed:
          completed++;
          break;
        case PersonalStatus.inProgress:
          inProgress++;
          break;
        case PersonalStatus.dropped:
          dropped++;
          break;
        default:
          break;
      }
    }

    return LibraryStats(
      totalAnime: totalAnime,
      totalManga: totalManga,
      totalManhwa: totalManhwa,
      completed: completed,
      inProgress: inProgress,
      dropped: dropped,
      totalEpisodesWatched: episodesWatched,
      totalChaptersRead: chaptersRead,
    );
  }

  // --- Saisons (détail par saison, indépendant du statut global) ---

  Future<List<Season>> getSeasons(String mediaItemId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'seasons',
      where: 'mediaItemId = ?',
      whereArgs: [mediaItemId],
      orderBy: 'seasonNumber ASC',
    );
    return rows.map(Season.fromMap).toList();
  }

  Future<Season> createSeason(Season draft) async {
    final db = await _dbHelper.database;
    final season = Season(
      id: _uuid.v4(),
      mediaItemId: draft.mediaItemId,
      seasonNumber: draft.seasonNumber,
      title: draft.title,
      status: draft.status,
      totalEpisodes: draft.totalEpisodes,
      availableEpisodes: draft.availableEpisodes,
      startDate: draft.startDate,
      endDate: draft.endDate,
      nextEpisodeDate: draft.nextEpisodeDate,
    );
    await db.insert('seasons', season.toMap());
    return season;
  }

  Future<void> updateSeason(Season season) async {
    final db = await _dbHelper.database;
    await db.update('seasons', season.toMap(),
        where: 'id = ?', whereArgs: [season.id]);
  }

  Future<void> deleteSeason(String id) async {
    final db = await _dbHelper.database;
    await db.delete('seasons', where: 'id = ?', whereArgs: [id]);
  }
}
