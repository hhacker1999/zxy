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

class Images {
  final List<Backdrop>? backdrops;
  final List<Backdrop>? logos;
  final List<Backdrop>? posters;

  Images({this.backdrops, this.logos, this.posters});

  factory Images.fromJson(Map<String, dynamic> json) => Images(
    backdrops: json["backdrops"] == null
        ? []
        : List<Backdrop>.from(
            json["backdrops"]!.map((x) => Backdrop.fromJson(x)),
          ),
    logos: json["logos"] == null
        ? []
        : List<Backdrop>.from(json["logos"]!.map((x) => Backdrop.fromJson(x))),
    posters: json["posters"] == null
        ? []
        : List<Backdrop>.from(
            json["posters"]!.map((x) => Backdrop.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "backdrops": backdrops == null
        ? []
        : List<dynamic>.from(backdrops!.map((x) => x.toJson())),
    "logos": logos == null
        ? []
        : List<dynamic>.from(logos!.map((x) => x.toJson())),
    "posters": posters == null
        ? []
        : List<dynamic>.from(posters!.map((x) => x.toJson())),
  };
}

class Backdrop {
  final double? aspectRatio;
  final int? height;
  final String? iso31661;
  final String? iso6391;
  final String? filePath;
  final double? voteAverage;
  final int? voteCount;
  final int? width;

  Backdrop({
    this.aspectRatio,
    this.height,
    this.iso31661,
    this.iso6391,
    this.filePath,
    this.voteAverage,
    this.voteCount,
    this.width,
  });

  factory Backdrop.fromJson(Map<String, dynamic> json) => Backdrop(
    aspectRatio: json["aspect_ratio"]?.toDouble(),
    height: json["height"],
    iso31661: json["iso_3166_1"],
    iso6391: json["iso_639_1"],
    filePath: json["file_path"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    width: json["width"],
  );

  Map<String, dynamic> toJson() => {
    "aspect_ratio": aspectRatio,
    "height": height,
    "iso_3166_1": iso31661,
    "iso_639_1": iso6391,
    "file_path": filePath,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "width": width,
  };
}

class ProductionCompany {
  final int? id;
  final String? logoPath;
  final String? name;
  final String? originCountry;

  ProductionCompany({this.id, this.logoPath, this.name, this.originCountry});

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      ProductionCompany(
        id: json["id"],
        logoPath: json["logo_path"],
        name: json["name"],
        originCountry: json["origin_country"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "logo_path": logoPath,
    "name": name,
    "origin_country": originCountry,
  };
}

class ProductionCountry {
  final String? iso31661;
  final String? name;

  ProductionCountry({this.iso31661, this.name});

  factory ProductionCountry.fromJson(Map<String, dynamic> json) =>
      ProductionCountry(iso31661: json["iso_3166_1"], name: json["name"]);

  Map<String, dynamic> toJson() => {"iso_3166_1": iso31661, "name": name};
}

class SpokenLanguage {
  final String? englishName;
  final String? iso6391;
  final String? name;

  SpokenLanguage({this.englishName, this.iso6391, this.name});

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) => SpokenLanguage(
    englishName: json["english_name"],
    iso6391: json["iso_639_1"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "english_name": englishName,
    "iso_639_1": iso6391,
    "name": name,
  };
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json["id"], name: json["name"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class Credits {
  final List<Cast>? cast;
  final List<Cast>? crew;

  Credits({this.cast, this.crew});

  factory Credits.fromJson(Map<String, dynamic> json) => Credits(
    cast: json["cast"] == null
        ? []
        : List<Cast>.from(json["cast"]!.map((x) => Cast.fromJson(x))),
    crew: json["crew"] == null
        ? []
        : List<Cast>.from(json["crew"]!.map((x) => Cast.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "cast": cast == null
        ? []
        : List<dynamic>.from(cast!.map((x) => x.toJson())),
    "crew": crew == null
        ? []
        : List<dynamic>.from(crew!.map((x) => x.toJson())),
  };
}

class Cast {
  final bool? adult;
  final int? gender;
  final int id;
  final String? knownForDepartment;
  final String name;
  final String? originalName;
  final double? popularity;
  final String? profilePath;
  final String? character;
  final String? creditId;
  final int? order;
  final String? department;
  final String? job;

  Cast({
    this.adult,
    this.gender,
    required this.id,
    this.knownForDepartment,
    required this.name,
    this.originalName,
    this.popularity,
    this.profilePath,
    this.character,
    this.creditId,
    this.order,
    this.department,
    this.job,
  });

  factory Cast.fromJson(Map<String, dynamic> json) => Cast(
    adult: json["adult"],
    gender: json["gender"],
    id: json["id"],
    knownForDepartment: json["known_for_department"],
    name: json["name"],
    originalName: json["original_name"],
    popularity: json["popularity"]?.toDouble(),
    profilePath: json["profile_path"],
    character: json["character"],
    creditId: json["credit_id"],
    order: json["order"],
    department: json["department"],
    job: json["job"],
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "gender": gender,
    "id": id,
    "known_for_department": knownForDepartment,
    "name": name,
    "original_name": originalName,
    "popularity": popularity,
    "profile_path": profilePath,
    "character": character,
    "credit_id": creditId,
    "order": order,
    "department": department,
    "job": job,
  };
}

class ExternalIds {
  final String? imdbId;
  final String? freebaseMid;
  final String? freebaseId;
  final int? tvdbId;
  final int? tvrageId;
  final String? wikidataId;
  final String? facebookId;
  final String? instagramId;
  final String? twitterId;

  ExternalIds({
    this.imdbId,
    this.freebaseMid,
    this.freebaseId,
    this.tvdbId,
    this.tvrageId,
    this.wikidataId,
    this.facebookId,
    this.instagramId,
    this.twitterId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) => ExternalIds(
    imdbId: json["imdb_id"],
    freebaseMid: json["freebase_mid"],
    freebaseId: json["freebase_id"],
    tvdbId: json["tvdb_id"],
    tvrageId: json["tvrage_id"],
    wikidataId: json["wikidata_id"],
    facebookId: json["facebook_id"],
    instagramId: json["instagram_id"],
    twitterId: json["twitter_id"],
  );

  Map<String, dynamic> toJson() => {
    "imdb_id": imdbId,
    "freebase_mid": freebaseMid,
    "freebase_id": freebaseId,
    "tvdb_id": tvdbId,
    "tvrage_id": tvrageId,
    "wikidata_id": wikidataId,
    "facebook_id": facebookId,
    "instagram_id": instagramId,
    "twitter_id": twitterId,
  };
}
