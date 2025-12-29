class Images {
  final List<ZxyImageInfo> backdrops;
  final int? id;
  final List<ZxyImageInfo> logos;
  final List<ZxyImageInfo> posters;

  Images({
    required this.backdrops,
    this.id,
    required this.logos,
    required this.posters,
  });

  factory Images.fromJson(Map<String, dynamic> json) => Images(
    backdrops: List<ZxyImageInfo>.from(
      json["backdrops"].map((x) => ZxyImageInfo.fromJson(x)),
    ),
    id: json["id"],
    logos: List<ZxyImageInfo>.from(json["logos"].map((x) => ZxyImageInfo.fromJson(x))),
    posters: List<ZxyImageInfo>.from(
      json["posters"].map((x) => ZxyImageInfo.fromJson(x)),
    ),
  );

}

class ZxyImageInfo {
  final double aspectRatio;
  final int height;
  final String? iso6391;
  final String filePath;
  final double voteAverage;
  final int voteCount;
  final int width;

  ZxyImageInfo({
    required this.aspectRatio,
    required this.height,
    required this.iso6391,
    required this.filePath,
    required this.voteAverage,
    required this.voteCount,
    required this.width,
  });

  factory ZxyImageInfo.fromJson(Map<String, dynamic> json) => ZxyImageInfo(
    aspectRatio: json["aspect_ratio"]?.toDouble(),
    height: json["height"],
    iso6391: json["iso_639_1"],
    filePath: json["file_path"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    width: json["width"],
  );

}
