class StreamItem {
  final String name;
  final String description;
  final String url;
  final BehaviorHints behaviorHints;

  StreamItem({
    required this.name,
    required this.description,
    required this.url,
    required this.behaviorHints,
  });

  factory StreamItem.fromJson(Map<String, dynamic> json) => StreamItem(
    name: json["name"]!,
    description: json["description"],
    url: json["url"],
    behaviorHints: BehaviorHints.fromJson(json["behaviorHints"]),
  );
}

class BehaviorHints {
  final String? bingeGroup;
  final int? videoSize;
  final String? filename;

  BehaviorHints({this.bingeGroup, this.videoSize, this.filename});

  factory BehaviorHints.fromJson(Map<String, dynamic> json) => BehaviorHints(
    bingeGroup: json["bingeGroup"],
    videoSize: json["videoSize"],
    filename: json["filename"],
  );

  Map<String, dynamic> toJson() => {
    "bingeGroup": bingeGroup,
    "videoSize": videoSize,
    "filename": filename,
  };
}
