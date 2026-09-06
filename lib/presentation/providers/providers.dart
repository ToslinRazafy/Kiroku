import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/media_item.dart';
import '../../data/models/profile.dart';
import '../../data/models/season.dart';
import '../../data/repositories/image_storage_service.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/profile_repository.dart';

// --- Repositories (singletons) ---

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final mediaRepositoryProvider = Provider((ref) => MediaRepository());
final imageStorageServiceProvider = Provider((ref) => ImageStorageService());

// --- Thème (clair / sombre / système) ---

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// --- Liste des profils ---

class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() {
    return ref.read(profileRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(profileRepositoryProvider).getAll());
  }

  Future<Profile> createProfile(String name, int colorValue) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .create(name: name, colorValue: colorValue);
    await refresh();
    return profile;
  }

  Future<void> deleteProfile(String id) async {
    await ref.read(profileRepositoryProvider).delete(id);
    await refresh();
  }

  Future<void> updateProfile(Profile profile) async {
    await ref.read(profileRepositoryProvider).update(profile);
    await refresh();
  }
}

final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(
        ProfilesNotifier.new);

// --- Profil actif ---

class ActiveProfileNotifier extends Notifier<Profile?> {
  @override
  Profile? build() => null;

  void select(Profile? profile) => state = profile;
}

final activeProfileProvider =
    NotifierProvider<ActiveProfileNotifier, Profile?>(
        ActiveProfileNotifier.new);

// --- Filtre de bibliothèque courant ---

class LibraryFilterNotifier extends Notifier<MediaFilter> {
  @override
  MediaFilter build() => const MediaFilter();

  void update(MediaFilter Function(MediaFilter) updater) {
    state = updater(state);
  }

  void reset() => state = const MediaFilter();
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, MediaFilter>(
        LibraryFilterNotifier.new);

// --- Contenus du profil actif, selon le filtre courant ---

/// Incrémenté à chaque écriture (création/modif/suppression) pour
/// invalider proprement les providers dérivés ci-dessous.
final libraryRevisionProvider = StateProvider<int>((ref) => 0);

final libraryProvider = FutureProvider<List<MediaItem>>((ref) async {
  ref.watch(libraryRevisionProvider);
  final profile = ref.watch(activeProfileProvider);
  final filter = ref.watch(libraryFilterProvider);
  if (profile == null) return [];
  return ref.read(mediaRepositoryProvider).getForProfile(
        profile.id,
        filter: filter,
      );
});

final continueWatchingProvider = FutureProvider<List<MediaItem>>((ref) async {
  ref.watch(libraryRevisionProvider);
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return [];
  return ref.read(mediaRepositoryProvider).getContinueWatching(profile.id);
});

final statsProvider = FutureProvider((ref) async {
  ref.watch(libraryRevisionProvider);
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return const LibraryStats();
  return ref.read(mediaRepositoryProvider).getStats(profile.id);
});

// --- Saisons d'une œuvre (détail indépendant du statut global) ---

final seasonsProvider =
    FutureProvider.family<List<Season>, String>((ref, mediaItemId) async {
  ref.watch(libraryRevisionProvider);
  return ref.read(mediaRepositoryProvider).getSeasons(mediaItemId);
});
