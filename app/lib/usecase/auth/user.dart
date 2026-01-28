class User {
  final String userId;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Profile> profiles;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.profiles,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json["user_id"],
    name: json["name"],
    email: json["email"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    profiles: List<Profile>.from(
      json["profiles"].map((x) => Profile.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "name": name,
    "email": email,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "profiles": List<dynamic>.from(profiles.map((x) => x.toJson())),
  };
}

class Profile {
  final int id;
  final String name;
  final String debridType;
  final bool isPinProtected;
  // final DateTime createdAt;
  // final DateTime updatedAt;

  Profile({
    required this.id,
    required this.name,
    required this.debridType,
    required this.isPinProtected
    // required this.createdAt,
    // required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json["id"],
    name: json["name"],
    debridType: json["debrid_type"] ?? "",
    isPinProtected:  json["is_pin_protected"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    // "created_at": createdAt.toIso8601String(),
    // "updated_at": updatedAt.toIso8601String(),
  };
}
