import '../../core/constants/enums.dart';

/// Modèle unique pour Anime / Manga / Manhwa.
///
/// Choix d'architecture : plutôt que trois tables séparées quasi
/// identiques, on utilise une seule entité avec un discriminant [type]
/// et des champs optionnels. Cela simplifie fortement les requêtes de
/// recherche/filtre/tri transverses (page d'accueil, statistiques,
/// bibliothèque globale) tout en respectant les champs spécifiques
/// demandés pour chaque type. Voir README pour le détail du choix.
///
/// Point important : [workStatus] (statut réel de publication) et
/// [personalStatus] (statut de l'utilisateur) sont deux notions
/// complètement indépendantes — voir enums.dart. Le détail par saison
/// (statut, épisodes, dates) vit dans une entité séparée [Season] pour
/// les animés, car une œuvre peut avoir des saisons à des stades très
/// différents (terminée / en cours / à venir) en même temps.
class MediaItem {
  final String id;
  final String profileId;
  final ContentType type;

  final String title;
  final String? originalTitle;
  final String? coverImagePath; // chemin local vers l'image copiée
  final String? description;

  /// Statut réel de publication/diffusion de l'œuvre (indépendant de
  /// l'avancement de l'utilisateur).
  final PublicationStatus workStatus;

  /// Une suite est-elle prévue/probable ? null = inconnu.
  final bool? hasSequel;

  /// Statut de l'utilisateur vis-à-vis de cette œuvre.
  final PersonalStatus personalStatus;

  final double? rating; // note personnelle, 0 à 10
  final String? comment;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> genres;

  // --- Champs spécifiques Anime ---
  final int? totalEpisodes; // total prévu, si connu
  final int? airedEpisodes; // nombre d'épisodes déjà diffusés/disponibles
  final int currentEpisode; // progression de l'utilisateur
  final int? totalSeasons;
  final int? currentSeason;
  final String? studio;
  final int? releaseYear;
  final WatchLanguage? watchLanguage;

  // --- Champs spécifiques Manga ---
  final int? totalVolumes;
  final int? publishedVolumes;
  final int currentVolume;
  final String? author;

  // --- Champs communs Manga / Manhwa ---
  final int? totalChapters;
  final int? publishedChapters;
  final int currentChapter;

  // --- Organisation détaillée optionnelle (arc narratif) ---
  final String? currentArcName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaItem({
    required this.id,
    required this.profileId,
    required this.type,
    required this.title,
    this.originalTitle,
    this.coverImagePath,
    this.description,
    this.workStatus = PublicationStatus.ongoing,
    this.hasSequel,
    this.personalStatus = PersonalStatus.toConsume,
    this.rating,
    this.comment,
    this.startDate,
    this.endDate,
    this.genres = const [],
    this.totalEpisodes,
    this.airedEpisodes,
    this.currentEpisode = 0,
    this.totalSeasons,
    this.currentSeason,
    this.studio,
    this.releaseYear,
    this.watchLanguage,
    this.totalVolumes,
    this.publishedVolumes,
    this.currentVolume = 0,
    this.author,
    this.totalChapters,
    this.publishedChapters,
    this.currentChapter = 0,
    this.currentArcName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progression 0.0 → 1.0, calculée automatiquement selon le type.
  /// Se base sur le nombre d'épisodes/chapitres disponibles quand le
  /// total prévu est inconnu, pour rester pertinente sur une œuvre en
  /// cours de diffusion.
  double get progress {
    if (type == ContentType.anime) {
      final denom = totalEpisodes ?? airedEpisodes;
      if (denom == null || denom == 0) return 0;
      return (currentEpisode / denom).clamp(0, 1).toDouble();
    } else {
      final denom = totalChapters ?? publishedChapters;
      if (denom == null || denom == 0) return 0;
      return (currentChapter / denom).clamp(0, 1).toDouble();
    }
  }

  String get progressLabel {
    if (type == ContentType.anime) {
      final total = totalEpisodes?.toString() ?? airedEpisodes?.toString() ?? '?';
      return 'Épisode $currentEpisode / $total';
    } else {
      final total = totalChapters?.toString() ?? publishedChapters?.toString() ?? '?';
      return 'Chapitre $currentChapter / $total';
    }
  }

  /// True si l'utilisateur a rattrapé tout ce qui est actuellement
  /// disponible, alors que l'œuvre elle-même continue (cas fréquent
  /// des shonen au long cours type One Piece).
  bool get isCaughtUpButOngoing =>
      workStatus == PublicationStatus.ongoing &&
      personalStatus == PersonalStatus.completed;

  MediaItem copyWith({
    String? title,
    String? originalTitle,
    bool clearOriginalTitle = false,
    String? coverImagePath,
    bool clearCover = false,
    String? description,
    PublicationStatus? workStatus,
    bool? hasSequel,
    bool clearHasSequel = false,
    PersonalStatus? personalStatus,
    double? rating,
    String? comment,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    List<String>? genres,
    int? totalEpisodes,
    bool clearTotalEpisodes = false,
    int? airedEpisodes,
    bool clearAiredEpisodes = false,
    int? currentEpisode,
    int? totalSeasons,
    int? currentSeason,
    String? studio,
    int? releaseYear,
    WatchLanguage? watchLanguage,
    int? totalVolumes,
    int? publishedVolumes,
    int? currentVolume,
    String? author,
    int? totalChapters,
    bool clearTotalChapters = false,
    int? publishedChapters,
    int? currentChapter,
    String? currentArcName,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id,
      profileId: profileId,
      type: type,
      title: title ?? this.title,
      originalTitle:
          clearOriginalTitle ? null : (originalTitle ?? this.originalTitle),
      coverImagePath:
          clearCover ? null : (coverImagePath ?? this.coverImagePath),
      description: description ?? this.description,
      workStatus: workStatus ?? this.workStatus,
      hasSequel: clearHasSequel ? null : (hasSequel ?? this.hasSequel),
      personalStatus: personalStatus ?? this.personalStatus,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      genres: genres ?? this.genres,
      totalEpisodes: clearTotalEpisodes
          ? null
          : (totalEpisodes ?? this.totalEpisodes),
      airedEpisodes:
          clearAiredEpisodes ? null : (airedEpisodes ?? this.airedEpisodes),
      currentEpisode: currentEpisode ?? this.currentEpisode,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      currentSeason: currentSeason ?? this.currentSeason,
      studio: studio ?? this.studio,
      releaseYear: releaseYear ?? this.releaseYear,
      watchLanguage: watchLanguage ?? this.watchLanguage,
      totalVolumes: totalVolumes ?? this.totalVolumes,
      publishedVolumes: publishedVolumes ?? this.publishedVolumes,
      currentVolume: currentVolume ?? this.currentVolume,
      author: author ?? this.author,
      totalChapters:
          clearTotalChapters ? null : (totalChapters ?? this.totalChapters),
      publishedChapters: publishedChapters ?? this.publishedChapters,
      currentChapter: currentChapter ?? this.currentChapter,
      currentArcName: currentArcName ?? this.currentArcName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'profileId': profileId,
        'type': type.name,
        'title': title,
        'originalTitle': originalTitle,
        'coverImagePath': coverImagePath,
        'description': description,
        'workStatus': workStatus.name,
        'hasSequel': hasSequel == null ? null : (hasSequel! ? 1 : 0),
        'personalStatus': personalStatus.name,
        'rating': rating,
        'comment': comment,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'genres': genres.join('|'),
        'totalEpisodes': totalEpisodes,
        'airedEpisodes': airedEpisodes,
        'currentEpisode': currentEpisode,
        'totalSeasons': totalSeasons,
        'currentSeason': currentSeason,
        'studio': studio,
        'releaseYear': releaseYear,
        'watchLanguage': watchLanguage?.name,
        'totalVolumes': totalVolumes,
        'publishedVolumes': publishedVolumes,
        'currentVolume': currentVolume,
        'author': author,
        'totalChapters': totalChapters,
        'publishedChapters': publishedChapters,
        'currentChapter': currentChapter,
        'currentArcName': currentArcName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MediaItem.fromMap(Map<String, Object?> map) => MediaItem(
        id: map['id'] as String,
        profileId: map['profileId'] as String,
        type: ContentTypeX.fromDb(map['type'] as String),
        title: map['title'] as String,
        originalTitle: map['originalTitle'] as String?,
        coverImagePath: map['coverImagePath'] as String?,
        description: map['description'] as String?,
        workStatus: map['workStatus'] == null
            ? PublicationStatus.ongoing
            : PublicationStatusX.fromDb(map['workStatus'] as String),
        hasSequel: map['hasSequel'] == null ? null : (map['hasSequel'] as int) == 1,
        personalStatus: PersonalStatusX.fromDb(
            (map['personalStatus'] ?? map['status']) as String),
        rating: (map['rating'] as num?)?.toDouble(),
        comment: map['comment'] as String?,
        startDate: map['startDate'] == null
            ? null
            : DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] == null
            ? null
            : DateTime.parse(map['endDate'] as String),
        genres: (map['genres'] as String? ?? '')
            .split('|')
            .where((g) => g.isNotEmpty)
            .toList(),
        totalEpisodes: map['totalEpisodes'] as int?,
        airedEpisodes: map['airedEpisodes'] as int?,
        currentEpisode: map['currentEpisode'] as int? ?? 0,
        totalSeasons: map['totalSeasons'] as int?,
        currentSeason: map['currentSeason'] as int?,
        studio: map['studio'] as String?,
        releaseYear: map['releaseYear'] as int?,
        watchLanguage: map['watchLanguage'] == null
            ? null
            : WatchLanguageX.fromDb(map['watchLanguage'] as String),
        totalVolumes: map['totalVolumes'] as int?,
        publishedVolumes: map['publishedVolumes'] as int?,
        currentVolume: map['currentVolume'] as int? ?? 0,
        author: map['author'] as String?,
        totalChapters: map['totalChapters'] as int?,
        publishedChapters: map['publishedChapters'] as int?,
        currentChapter: map['currentChapter'] as int? ?? 0,
        currentArcName: map['currentArcName'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
