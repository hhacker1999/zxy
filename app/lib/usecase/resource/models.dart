import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';

class ZxyPaginatedResponse<T> {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<T> results;

  const ZxyPaginatedResponse({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.results,
  });

  factory ZxyPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    List<T> Function(List<Map<String, dynamic>>) resultParser,
  ) {
    return ZxyPaginatedResponse<T>(
      page: json["page"],
      totalPages: json["total_pages"],
      totalResults: json["total_results"],
      results: resultParser(List<Map<String, dynamic>>.from(json["results"])),
    );
  }
}

class ZxyMedia {
  final int id;
  final bool adult;
  final String? backdropPath;
  final List<int> genreIds;
  final String originalLanguage;
  final String? originalTitle;
  final String? originalName;
  final String overview;
  final double? popularity;
  final String posterPath;
  DateTime? releaseDate;
  DateTime? firstAirDate;
  final String? title;
  final String? name;
  final double? voteAverage;
  final int? voteCount;
  final ZxyMediaType type;

  ZxyMedia({
    required this.adult,
    this.backdropPath,
    required this.genreIds,
    required this.type,
    required this.id,
    required this.originalLanguage,
    this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    this.releaseDate,
    this.firstAirDate,
    this.title,
    required this.voteAverage,
    required this.voteCount,
    this.name,
    this.originalName,
  });

  @override
  factory ZxyMedia.fromJson(Map<String, dynamic> json, ZxyMediaType type) =>
      ZxyMedia(
        adult: json["adult"],
        backdropPath: json["backdrop_path"],
        genreIds: json["genre_ids"] != null
            ? List<int>.from(json["genre_ids"].map((x) => x))
            : [],
        id: json["id"],
        type: type,
        originalLanguage: json["original_language"]!,
        originalTitle: json["original_title"],
        originalName: json["original_name"],
        overview: json["overview"],
        popularity: json["popularity"]?.toDouble() ?? 0,
        posterPath: json["poster_path"] ?? "",
        releaseDate: json["releaseDate"] != null
            ? DateTime.parse(json["release_date"])
            : null,
        firstAirDate: json["first_air_date"] != null
            ? DateTime.tryParse(json["first_air_date"])
            : null,
        title: json["title"],
        name: json["name"],
        voteAverage: json["vote_average"]?.toDouble() ?? 0,
        voteCount: json["vote_count"] ?? 0,
      );
}

class GenreResponse {
  final List<Genre> movieGenre;
  final List<Genre> showGenre;

  GenreResponse({required this.movieGenre, required this.showGenre});

  factory GenreResponse.fromJson(Map<String, dynamic> json) => GenreResponse(
    movieGenre: List<Genre>.from(
      json["movie_genre"].map((x) => Genre.fromJson(x)),
    ),
    showGenre: List<Genre>.from(
      json["show_genre"].map((x) => Genre.fromJson(x)),
    ),
  );
}

class ImageConfiguation {
  final String baseUrl;
  final String secureBaseUrl;
  final List<String> backdropSizes;
  final List<String> logoSizes;
  final List<String> posterSizes;
  final List<String> profileSizes;
  final List<String> stillSizes;

  ImageConfiguation({
    required this.baseUrl,
    required this.secureBaseUrl,
    required this.backdropSizes,
    required this.logoSizes,
    required this.posterSizes,
    required this.profileSizes,
    required this.stillSizes,
  });

  factory ImageConfiguation.fromJson(Map<String, dynamic> json) =>
      ImageConfiguation(
        baseUrl: json["base_url"],
        secureBaseUrl: json["secure_base_url"],
        backdropSizes: List<String>.from(json["backdrop_sizes"].map((x) => x)),
        logoSizes: List<String>.from(json["logo_sizes"].map((x) => x)),
        posterSizes: List<String>.from(json["poster_sizes"].map((x) => x)),
        profileSizes: List<String>.from(json["profile_sizes"].map((x) => x)),
        stillSizes: List<String>.from(json["still_sizes"].map((x) => x)),
      );
}
