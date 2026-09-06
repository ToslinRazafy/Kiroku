import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Point d'accès unique à la base SQLite locale.
///
/// SQLite (via sqflite) a été choisi plutôt que Hive/Isar car les données
/// sont fortement relationnelles (profils -> contenus -> saisons, filtres
/// transverses, agrégations pour les statistiques) : le SQL natif fait ce
/// travail simplement et sans étape de génération de code, ce qui garde
/// le projet facile à compiler. Aucune donnée ne quitte jamais l'appareil.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'otaku_tracker.db';
  // v2 : sépare le statut réel de publication (workStatus) du statut
  // personnel (personalStatus), ajoute le titre original, la langue de
  // visionnage, les compteurs "publié/disponible" distincts du "total
  // prévu", et introduit la table `seasons` pour le détail par saison.
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            avatarPath TEXT,
            colorValue INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE media_items (
            id TEXT PRIMARY KEY,
            profileId TEXT NOT NULL,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            originalTitle TEXT,
            coverImagePath TEXT,
            description TEXT,
            workStatus TEXT NOT NULL DEFAULT 'ongoing',
            hasSequel INTEGER,
            personalStatus TEXT NOT NULL,
            rating REAL,
            comment TEXT,
            startDate TEXT,
            endDate TEXT,
            genres TEXT,
            totalEpisodes INTEGER,
            airedEpisodes INTEGER,
            currentEpisode INTEGER NOT NULL DEFAULT 0,
            totalSeasons INTEGER,
            currentSeason INTEGER,
            studio TEXT,
            releaseYear INTEGER,
            watchLanguage TEXT,
            totalVolumes INTEGER,
            publishedVolumes INTEGER,
            currentVolume INTEGER NOT NULL DEFAULT 0,
            author TEXT,
            totalChapters INTEGER,
            publishedChapters INTEGER,
            currentChapter INTEGER NOT NULL DEFAULT 0,
            currentArcName TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE seasons (
            id TEXT PRIMARY KEY,
            mediaItemId TEXT NOT NULL,
            seasonNumber INTEGER NOT NULL,
            title TEXT,
            status TEXT NOT NULL DEFAULT 'ongoing',
            totalEpisodes INTEGER,
            availableEpisodes INTEGER,
            startDate TEXT,
            endDate TEXT,
            nextEpisodeDate TEXT,
            FOREIGN KEY (mediaItemId) REFERENCES media_items (id) ON DELETE CASCADE
          );
        ''');

        await db.execute(
          'CREATE INDEX idx_media_profile ON media_items (profileId);',
        );
        await db.execute(
          'CREATE INDEX idx_media_type ON media_items (type);',
        );
        await db.execute(
          'CREATE INDEX idx_media_personal_status ON media_items (personalStatus);',
        );
        await db.execute(
          'CREATE INDEX idx_seasons_media ON seasons (mediaItemId);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // On ajoute les colonnes une par une : ADD COLUMN est supporté
          // par toutes les versions de SQLite embarquées, contrairement à
          // RENAME COLUMN ou DROP COLUMN qui ne le sont pas partout. La
          // colonne historique `status` reste en base (inutilisée) pour
          // ne rien casser sur d'anciennes installations.
          await db.execute(
              "ALTER TABLE media_items ADD COLUMN personalStatus TEXT NOT NULL DEFAULT 'toConsume';");
          await db.execute(
              'UPDATE media_items SET personalStatus = status;');
          await db.execute(
              "ALTER TABLE media_items ADD COLUMN workStatus TEXT NOT NULL DEFAULT 'completed';");
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN originalTitle TEXT;');
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN hasSequel INTEGER;');
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN watchLanguage TEXT;');
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN airedEpisodes INTEGER;');
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN publishedChapters INTEGER;');
          await db.execute(
              'ALTER TABLE media_items ADD COLUMN publishedVolumes INTEGER;');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS seasons (
              id TEXT PRIMARY KEY,
              mediaItemId TEXT NOT NULL,
              seasonNumber INTEGER NOT NULL,
              title TEXT,
              status TEXT NOT NULL DEFAULT 'ongoing',
              totalEpisodes INTEGER,
              availableEpisodes INTEGER,
              startDate TEXT,
              endDate TEXT,
              nextEpisodeDate TEXT,
              FOREIGN KEY (mediaItemId) REFERENCES media_items (id) ON DELETE CASCADE
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_seasons_media ON seasons (mediaItemId);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_media_personal_status ON media_items (personalStatus);',
          );
        }
      },
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
