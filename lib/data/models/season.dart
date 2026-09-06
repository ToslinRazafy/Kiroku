import '../../core/constants/enums.dart';

/// Une saison d'un anime, avec son propre statut de publication.
///
/// Une œuvre "en cours" peut très bien avoir sa saison 1 "terminée",
/// sa saison 2 "en cours" et une saison 3 déjà annoncée mais "à venir" :
/// chaque saison possède donc son cycle de vie propre, indépendant du
/// statut global de l'œuvre (voir [PublicationStatus]).
class Season {
  final String id;
  final String mediaItemId;
  final int seasonNumber;
  final String? title;
  final PublicationStatus status;

  // Toutes les informations suivantes sont optionnelles : quand
  // l'information est inconnue, le champ reste null et l'UI doit
  // afficher "Inconnu" plutôt que d'inventer une valeur.
  final int? totalEpisodes; // nombre total d'épisodes prévus pour la saison
  final int? availableEpisodes; // nombre d'épisodes actuellement disponibles
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextEpisodeDate;

  const Season({
    required this.id,
    required this.mediaItemId,
    required this.seasonNumber,
    this.title,
    this.status = PublicationStatus.ongoing,
    this.totalEpisodes,
    this.availableEpisodes,
    this.startDate,
    this.endDate,
    this.nextEpisodeDate,
  });

  Season copyWith({
    int? seasonNumber,
    String? title,
    bool clearTitle = false,
    PublicationStatus? status,
    int? totalEpisodes,
    bool clearTotalEpisodes = false,
    int? availableEpisodes,
    bool clearAvailableEpisodes = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? nextEpisodeDate,
    bool clearNextEpisodeDate = false,
  }) {
    return Season(
      id: id,
      mediaItemId: mediaItemId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: clearTitle ? null : (title ?? this.title),
      status: status ?? this.status,
      totalEpisodes: clearTotalEpisodes
          ? null
          : (totalEpisodes ?? this.totalEpisodes),
      availableEpisodes: clearAvailableEpisodes
          ? null
          : (availableEpisodes ?? this.availableEpisodes),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      nextEpisodeDate: clearNextEpisodeDate
          ? null
          : (nextEpisodeDate ?? this.nextEpisodeDate),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'mediaItemId': mediaItemId,
        'seasonNumber': seasonNumber,
        'title': title,
        'status': status.name,
        'totalEpisodes': totalEpisodes,
        'availableEpisodes': availableEpisodes,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'nextEpisodeDate': nextEpisodeDate?.toIso8601String(),
      };

  factory Season.fromMap(Map<String, Object?> map) => Season(
        id: map['id'] as String,
        mediaItemId: map['mediaItemId'] as String,
        seasonNumber: map['seasonNumber'] as int,
        title: map['title'] as String?,
        status: PublicationStatusX.fromDb(map['status'] as String),
        totalEpisodes: map['totalEpisodes'] as int?,
        availableEpisodes: map['availableEpisodes'] as int?,
        startDate: map['startDate'] == null
            ? null
            : DateTime.parse(map['startDate'] as String),
        endDate: map['endDate'] == null
            ? null
            : DateTime.parse(map['endDate'] as String),
        nextEpisodeDate: map['nextEpisodeDate'] == null
            ? null
            : DateTime.parse(map['nextEpisodeDate'] as String),
      );
}
