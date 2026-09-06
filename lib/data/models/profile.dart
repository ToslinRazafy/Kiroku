class Profile {
  final String id;
  final String name;
  final String? avatarPath;
  final int colorValue; // couleur d'accent pour différencier les profils
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.colorValue,
    required this.createdAt,
  });

  Profile copyWith({
    String? name,
    String? avatarPath,
    bool clearAvatar = false,
    int? colorValue,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromMap(Map<String, Object?> map) => Profile(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarPath: map['avatarPath'] as String?,
        colorValue: map['colorValue'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
