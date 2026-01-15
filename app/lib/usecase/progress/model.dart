class WatchProgress {
  final String mediaId;
  final double progress;
  final int userId;
  final int profileId;
  final bool isWatched;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WatchProgress({
    required this.mediaId,
    required this.progress,
    required this.userId,
    required this.profileId,
    required this.isWatched,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatchProgress.fromJson(Map<String, dynamic> json) =>
      WatchProgress(
        mediaId: json["MediaId"],
        progress: json["Progress"]?.toDouble(),
        userId: json["UserId"],
        profileId: json["ProfileId"],
        isWatched: json["IsWatched"],
        createdAt: DateTime.parse(json["CreatedAt"]),
        updatedAt: DateTime.parse(json["UpdatedAt"]),
      );

  Map<String, dynamic> toJson() => {
    "MediaId": mediaId,
    "Progress": progress,
    "UserId": userId,
    "ProfileId": profileId,
    "IsWatched": isWatched,
    "CreatedAt": createdAt.toIso8601String(),
    "UpdatedAt": updatedAt.toIso8601String(),
  };
}
