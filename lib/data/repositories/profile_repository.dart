import 'package:uuid/uuid.dart';

import '../local/database_helper.dart';
import '../models/profile.dart';

class ProfileRepository {
  final DatabaseHelper _dbHelper;
  static const _uuid = Uuid();

  ProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Profile>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('profiles', orderBy: 'createdAt ASC');
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> create({required String name, required int colorValue}) async {
    final db = await _dbHelper.database;
    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await db.insert('profiles', profile.toMap());
    return profile;
  }

  Future<void> update(Profile profile) async {
    final db = await _dbHelper.database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Supprime le profil ainsi que tout son contenu associé
  /// (contrainte FOREIGN KEY ... ON DELETE CASCADE).
  Future<void> delete(String profileId) async {
    final db = await _dbHelper.database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
  }
}
