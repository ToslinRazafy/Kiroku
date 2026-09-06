/// Type de contenu géré par l'application.
enum ContentType { anime, manga, manhwa }

extension ContentTypeX on ContentType {
  String get label {
    switch (this) {
      case ContentType.anime:
        return 'Anime';
      case ContentType.manga:
        return 'Manga';
      case ContentType.manhwa:
        return 'Manhwa';
    }
  }

  static ContentType fromDb(String value) =>
      ContentType.values.firstWhere((e) => e.name == value);
}

/// Statut RÉEL de publication/diffusion de l'œuvre (ou d'une saison).
///
/// Complètement indépendant de la progression de l'utilisateur : une
/// œuvre "en cours" de diffusion peut très bien être "terminée" du
/// point de vue de l'utilisateur (il a vu tout ce qui est disponible).
/// Voir [PersonalStatus] pour le statut propre à l'utilisateur.
enum PublicationStatus { ongoing, completed, upcoming }

extension PublicationStatusX on PublicationStatus {
  String get label {
    switch (this) {
      case PublicationStatus.ongoing:
        return 'En cours';
      case PublicationStatus.completed:
        return 'Terminé';
      case PublicationStatus.upcoming:
        return 'À venir';
    }
  }

  static PublicationStatus fromDb(String value) =>
      PublicationStatus.values.firstWhere((e) => e.name == value);
}

/// Statut de l'utilisateur vis-à-vis d'une œuvre : totalement
/// indépendant du statut réel de publication ([PublicationStatus]).
enum PersonalStatus { toConsume, inProgress, completed, dropped, rewatch }

extension PersonalStatusX on PersonalStatus {
  String labelFor(ContentType type) {
    final isReading = type == ContentType.manga || type == ContentType.manhwa;
    switch (this) {
      case PersonalStatus.toConsume:
        return isReading ? 'À lire' : 'À regarder';
      case PersonalStatus.inProgress:
        return 'En cours';
      case PersonalStatus.completed:
        return 'Terminé';
      case PersonalStatus.dropped:
        return 'Abandonné';
      case PersonalStatus.rewatch:
        return isReading ? 'À relire' : 'À revoir';
    }
  }

  static PersonalStatus fromDb(String value) =>
      PersonalStatus.values.firstWhere((e) => e.name == value);
}

/// Langue / format dans lequel l'utilisateur regarde un anime.
/// Représente son expérience de visionnage, pas les langues
/// officiellement disponibles pour l'œuvre.
enum WatchLanguage { vf, vostfr, vfAndVostfr }

extension WatchLanguageX on WatchLanguage {
  String get label {
    switch (this) {
      case WatchLanguage.vf:
        return 'VF';
      case WatchLanguage.vostfr:
        return 'VOSTFR';
      case WatchLanguage.vfAndVostfr:
        return 'VF + VOSTFR';
    }
  }

  static WatchLanguage fromDb(String value) =>
      WatchLanguage.values.firstWhere((e) => e.name == value);
}

enum SortMode {
  nameAsc,
  nameDesc,
  lastModified,
  progression,
  rating,
  dateAdded,
}

extension SortModeX on SortMode {
  String get label {
    switch (this) {
      case SortMode.nameAsc:
        return 'Nom A → Z';
      case SortMode.nameDesc:
        return 'Nom Z → A';
      case SortMode.lastModified:
        return 'Dernière modification';
      case SortMode.progression:
        return 'Progression';
      case SortMode.rating:
        return 'Note';
      case SortMode.dateAdded:
        return "Date d'ajout";
    }
  }
}

const List<String> kDefaultGenres = [
  'Action', 'Aventure', 'Comédie', 'Drame', 'Fantastique', 'Horreur',
  'Romance', 'Science-fiction', 'Seinen', 'Shonen', 'Shojo', 'Slice of life',
  'Sport', 'Surnaturel', 'Thriller', 'Mystère', 'Isekai', 'Mecha',
];
