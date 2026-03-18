import 'package:zxy_app/usecase/resource/models.dart';

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

  factory WatchProgress.fromJson(Map<String, dynamic> json) => WatchProgress(
    mediaId: json["MediaId"],
    progress: json["Progress"]?.toDouble(),
    userId: json["UserId"],
    profileId: json["ProfileId"],
    isWatched: json["IsWatched"],
    createdAt: DateTime.parse(json["CreatedAt"]),
    updatedAt: DateTime.parse(json["UpdatedAt"]),
  );

  factory WatchProgress.empty(String mediaId, {double? progress}) =>
      WatchProgress(
        mediaId: mediaId,
        progress: progress ?? 0,
        userId: 0,
        profileId: 0,
        isWatched: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

  WatchProgress copyWith({
    String? mediaId,
    bool? isWatched,
    DateTime? createdAt,
    int? profileId,
    double? progress,
    int? userId,
    DateTime? updatedAt,
  }) {
    return WatchProgress(
      mediaId: mediaId ?? this.mediaId,
      isWatched: isWatched ?? this.isWatched,
      createdAt: createdAt ?? this.createdAt,
      profileId: profileId ?? this.profileId,
      progress: progress ?? this.progress,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContinueWatchingItem {
  final ZxyMedia media;
  final WatchProgress progress;

  ContinueWatchingItem({required this.media, required this.progress});
  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    return ContinueWatchingItem(
      media: ZxyMedia.fromJson(json["media"], null),
      progress: WatchProgress.fromJson(json["progress"]),
    );
  }
}
