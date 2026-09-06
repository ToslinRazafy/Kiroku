import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Gère la copie des images sélectionnées par l'utilisateur vers un
/// répertoire interne à l'application (dossier `covers/`), afin que
/// les couvertures restent disponibles même si l'image d'origine
/// (galerie) est supprimée ou déplacée. Tout reste 100% local.
class ImageStorageService {
  static const _uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _coversDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ouvre la galerie, copie l'image choisie localement et renvoie
  /// son nouveau chemin. Retourne `null` si l'utilisateur annule.
  Future<String?> pickAndStoreImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await _coversDir();
    final ext = p.extension(picked.path);
    final newPath = p.join(dir.path, '${_uuid.v4()}$ext');
    await File(picked.path).copy(newPath);
    return newPath;
  }

  Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
