# Otaku Tracker

Application Flutter locale (hors-ligne) pour suivre tes animes, mangas et
manhwas : progression, statuts, notes, plusieurs profils, recherche,
filtres et statistiques.

> ⚠️ **Important sur la façon dont ce projet a été livré.** Je n'ai pas
> d'environnement Flutter/Dart ni d'accès réseau pour exécuter
> `flutter create`, `flutter pub get` ou `flutter run`/`build` dans cet
> environnement. J'ai donc écrit le projet entièrement à la main (tous les
> fichiers `lib/`, `pubspec.yaml`, etc.) en suivant scrupuleusement les
> API Flutter / Riverpod / sqflite, mais **je n'ai pas pu le compiler ni
> le tester moi-même**. Il faudra le compiler une première fois chez toi
> (voir ci-dessous) — c'est là que d'éventuelles petites erreurs de
> typage seraient visibles et rapides à corriger.

## 1. Mise en route

Ce dossier ne contient que le code source Dart (`lib/`) et `pubspec.yaml` :
les dossiers `android/`, `ios/`, etc. ne sont pas générés (ils nécessitent
le SDK Flutter). Pour obtenir un projet compilable :

```bash
# 1. Crée un squelette de projet Flutter à côté
flutter create otaku_tracker_app
cd otaku_tracker_app

# 2. Remplace pubspec.yaml et lib/ par ceux fournis ici
#    (garde les dossiers android/ ios/ etc. générés à l'étape 1)
cp -r ../otaku_tracker/lib .
cp ../otaku_tracker/pubspec.yaml .
cp ../otaku_tracker/analysis_options.yaml .

# 3. Récupère les dépendances
flutter pub get

# 4. Lance l'application
flutter run
```

Si `flutter pub get` ou la compilation signale une erreur, c'est très
probablement une erreur mineure (import manquant, nom d'API légèrement
différent selon la version de Flutter) — indique-la moi et je la corrige
immédiatement.

## 2. Choix techniques

| Besoin | Choix | Pourquoi |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod`) | Demandé dans le cahier des charges, testable, pas de code-gen requis (on utilise `Notifier`/`AsyncNotifier`, pas `riverpod_generator`) |
| Stockage local | **SQLite via `sqflite`** | Les données sont relationnelles (profils → contenus, filtres transverses, agrégats pour les stats) : SQL natif reste simple, robuste, et ne nécessite pas d'étape de génération de code (contrairement à Drift/Isar), ce qui limite les risques de compilation puisque je n'ai pas pu tester le build |
| Images | Copiées dans le dossier de documents de l'app (`path_provider` + `image_picker`) | Reste disponible même si l'image d'origine de la galerie est supprimée ; 100 % local |
| UI | Material 3, thème clair/sombre piloté par un provider | Demandé explicitement |

## 3. Architecture des dossiers

```
lib/
  core/
    constants/enums.dart      # ContentType, ContentStatus, SortMode, genres par défaut
    theme/app_theme.dart      # Thèmes Material 3 clair/sombre
  data/
    local/database_helper.dart        # Ouverture DB, schéma SQL, migrations
    models/                           # Profile, MediaItem (+ mapping toMap/fromMap)
    repositories/                     # ProfileRepository, MediaRepository, ImageStorageService
  presentation/
    providers/providers.dart          # Tous les providers Riverpod
    screens/
      profile/    # Sélection / création de profil
      home/       # Tableau de bord + navigation par onglets
      library/    # Recherche, filtres, tri, liste des contenus
      content/    # Formulaire ajout/édition + écran détail
      stats/      # Statistiques et graphiques (fl_chart)
      settings/   # Thème, changement de profil
    widgets/       # ContentCard, AppProgressBar (composants réutilisables)
  main.dart
```

Séparation claire : les écrans (`presentation`) ne parlent jamais
directement à SQLite — ils passent par les providers, qui appellent les
repositories (`data`), qui seuls connaissent `sqflite`. Pour ajouter une
synchronisation cloud plus tard, il suffira d'ajouter un
`RemoteMediaRepository` et de le brancher derrière la même interface,
sans toucher aux écrans.

## 4. Simplifications assumées (à lire avant de juger le résultat incomplet)

Le cahier des charges est très large. Pour livrer une application qui
fonctionne réellement plutôt qu'une coquille vide, j'ai fait les choix
suivants — tous facilement réversibles :

- **Un seul modèle `MediaItem`** (avec un champ `type`) plutôt que trois
  tables Anime/Manga/Manhwa séparées. Tous les champs demandés sont
  présents, mais certains sont simplement ignorés/masqués selon le type
  dans le formulaire. Cela simplifie énormément la bibliothèque globale,
  la recherche, les filtres et les statistiques (qui doivent brasser les
  trois types ensemble).
- **Hiérarchie Saison / Arc / Tome / Chapitre** : implémentée sous forme
  de champs simples (saison actuelle/totale pour les animes, "arc actuel"
  en texte libre + tome actuel/total pour les mangas) plutôt qu'un arbre
  récursif complet Saison→Épisodes / Arc→Tome→Chapitres. Cela couvre le
  besoin de suivi détaillé de façon optionnelle, sans complexifier le
  schéma de base de données. Une vraie hiérarchie récursive (table
  `sub_units` avec `parent_id`) est un ajout naturel plus tard si tu en
  as vraiment besoin — l'architecture en couches ne bloque pas cet ajout.
- **Statistiques** : compteurs + un graphique en secteurs (répartition
  par type) et un graphique en barres (répartition par statut). D'autres
  graphiques (évolution dans le temps, etc.) peuvent être ajoutés dans
  `stats_screen.dart` en réutilisant les mêmes données.
- Pas de tests automatisés inclus (le cahier des charges demande de
  "tester les fonctionnalités principales" — je n'ai pas pu exécuter de
  tests faute d'environnement Flutter ; je recommande de tester
  manuellement après le premier `flutter run`, notamment création de
  profil, ajout d'un contenu de chaque type, incrément de progression,
  suppression, changement de thème).

## 5. Évolutions futures déjà anticipées par l'architecture

Comme demandé, rien de ce qui suit n'est implémenté, mais rien ne
l'empêche :

- **Synchronisation cloud / compte utilisateur** : ajouter un
  repository distant implémentant la même interface que
  `MediaRepository`/`ProfileRepository`.
- **Sauvegarde/restauration locale** : `sqflite` stocke tout dans un
  seul fichier `.db` + le dossier `covers/` — un simple export/zip de
  ces deux emplacements suffit.
- **API externe (auto-remplissage titre/description/image)** : ajouter
  un service réseau optionnel appelé uniquement depuis le formulaire
  d'ajout, sans changer le stockage local.
- **Notifications de nouveaux épisodes/chapitres** : nécessiterait une
  source de données externe (non prévue en v1, hors-ligne par design).

## 6. Confidentialité

Toutes les données (textes et images) sont stockées uniquement dans le
stockage interne de l'application (base SQLite + dossier `covers/`).
Aucun réseau, aucun compte, aucun serveur.
