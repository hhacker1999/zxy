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

class ZxyStreamResponse {
  final List<ZxyResolutionItem> uhd;
  final List<ZxyResolutionItem> fhd;
  final List<ZxyResolutionItem> hd;

  const ZxyStreamResponse({
    required this.uhd,
    required this.fhd,
    required this.hd,
  });

  factory ZxyStreamResponse.fromJson(Map<String, dynamic> json) {
    return ZxyStreamResponse(
      uhd: json["uhd"] != null
          ? List.from(
              json["uhd"],
            ).map((e) => ZxyResolutionItem.fromJson(e)).toList()
          : [],
      fhd: json["fhd"] != null
          ? List.from(
              json["fhd"],
            ).map((e) => ZxyResolutionItem.fromJson(e)).toList()
          : [],
      hd: json["hd"] != null
          ? List.from(
              json["hd"],
            ).map((e) => ZxyResolutionItem.fromJson(e)).toList()
          : [],
    );
  }
}

class ZxyResolutionItem {
  final List<String> visualTags;
  final List<String> audioTags;
  final String? fileName;
  final List<String> languageCodes;
  final int? size;
  final String url;
  final String? quality;
  final String resolution;

  ZxyResolutionItem({
    required this.visualTags,
    required this.audioTags,
    this.fileName,
    required this.languageCodes,
    this.size,
    required this.url,
    this.quality,
    required this.resolution,
  });

  factory ZxyResolutionItem.fromJson(Map<String, dynamic> json) {
    return ZxyResolutionItem(
      visualTags: json["visual_tags"] == null
          ? []
          : List<String>.from(json["visual_tags"]!.map((x) => x)),
      audioTags: json["audio_tags"] == null
          ? []
          : List<String>.from(json["audio_tags"]!.map((x) => x)),
      fileName: json["file_name"],
      languageCodes: json["language_codes"] == null
          ? []
          : List<String>.from(json["language_codes"]!.map((x) => x)),
      size: json["size"],
      url: json["url"],
      quality: json["quality"],
      resolution: json["resolution"],
    );
  }
}
