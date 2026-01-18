import 'package:zxy_app/usecase/resource/models.dart';

class SeriesDetails {
  final bool? adult;
  final String? backdropPath;
  final List<CreatedBy>? createdBy;
  final List<dynamic>? episodeRunTime;
  final DateTime? firstAirDate;
  final List<Genre> genres;
  final String? homepage;
  final int id;
  final bool? inProduction;
  final List<String>? languages;
  final DateTime? lastAirDate;
  final Episode? lastEpisodeToAir;
  final String name;
  final Episode? nextEpisodeToAir;
  final List<Network>? networks;
  final int? numberOfEpisodes;
  final int? numberOfSeasons;
  final List<dynamic>? originCountry;
  final String? originalLanguage;
  final String originalName;
  final String overview;
  final double? popularity;
  final String? posterPath;
  final List<Network>? productionCompanies;
  final List<ProductionCountry>? productionCountries;
  final List<SpokenLanguage>? spokenLanguages;
  final String? status;
  final String? tagline;
  final String? type;
  final double voteAverage;
  final int? voteCount;
  final List<Season> seasons;
  final ExternalIds externalIds;
  final Credits? credits;
  final Images? images;
  final SimilarShows? similar;

  SeriesDetails({
    this.adult,
    this.backdropPath,
    this.createdBy,
    this.episodeRunTime,
    this.firstAirDate,
    required this.genres,
    this.homepage,
    required this.id,
    this.inProduction,
    this.languages,
    this.lastAirDate,
    this.lastEpisodeToAir,
    required this.name,
    this.nextEpisodeToAir,
    this.networks,
    this.numberOfEpisodes,
    this.numberOfSeasons,
    this.originCountry,
    this.originalLanguage,
    required this.originalName,
    required this.overview,
    this.popularity,
    this.posterPath,
    this.productionCompanies,
    this.productionCountries,
    this.spokenLanguages,
    this.status,
    this.tagline,
    this.type,
    required this.voteAverage,
    this.voteCount,
    required this.seasons,
    required this.externalIds,
    this.credits,
    this.images,
    this.similar,
  });

  factory SeriesDetails.fromJson(Map<String, dynamic> json) => SeriesDetails(
    adult: json["adult"],
    backdropPath: json["backdrop_path"],
    createdBy: json["created_by"] == null
        ? []
        : List<CreatedBy>.from(
            json["created_by"]!.map((x) => CreatedBy.fromJson(x)),
          ),
    episodeRunTime: json["episode_run_time"] == null
        ? []
        : List<dynamic>.from(json["episode_run_time"]!.map((x) => x)),
    firstAirDate: json["first_air_date"] == null
        ? null
        : DateTime.parse(json["first_air_date"]),
    genres: json["genres"] == null
        ? []
        : List<Genre>.from(json["genres"]!.map((x) => Genre.fromJson(x))),
    homepage: json["homepage"],
    id: json["id"],
    inProduction: json["in_production"],
    languages: json["languages"] == null
        ? []
        : List<String>.from(json["languages"]!.map((x) => x)),
    lastAirDate: DateTime.tryParse(json["last_air_date"]),
    lastEpisodeToAir: json["last_episode_to_air"] == null
        ? null
        : Episode.fromJson(json["last_episode_to_air"]),
    name: json["name"],
    nextEpisodeToAir: json["next_episode_to_air"] == null
        ? null
        : Episode.fromJson(json["next_episode_to_air"]),
    networks: json["networks"] == null
        ? []
        : List<Network>.from(json["networks"]!.map((x) => Network.fromJson(x))),
    numberOfEpisodes: json["number_of_episodes"],
    numberOfSeasons: json["number_of_seasons"],
    originCountry: json["origin_country"],
    originalLanguage: json["original_language"],
    originalName: json["original_name"],
    overview: json["overview"],
    popularity: json["popularity"]?.toDouble(),
    posterPath: json["poster_path"],
    productionCompanies: json["production_companies"] == null
        ? []
        : List<Network>.from(
            json["production_companies"]!.map((x) => Network.fromJson(x)),
          ),
    productionCountries: json["production_countries"] == null
        ? []
        : List<ProductionCountry>.from(
            json["production_countries"]!.map(
              (x) => ProductionCountry.fromJson(x),
            ),
          ),
    spokenLanguages: json["spoken_languages"] == null
        ? []
        : List<SpokenLanguage>.from(
            json["spoken_languages"]!.map((x) => SpokenLanguage.fromJson(x)),
          ),
    status: json["status"],
    tagline: json["tagline"],
    type: json["type"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    seasons: json["seasons"] == null
        ? []
        : List<Season>.from(json["seasons"]!.map((x) => Season.fromJson(x))),
    externalIds: ExternalIds.fromJson(json["external_ids"]),
    credits: json["credits"] == null ? null : Credits.fromJson(json["credits"]),
    images: json["images"] == null ? null : Images.fromJson(json["images"]),
    similar: json["similar"] == null
        ? null
        : SimilarShows.fromJson(json["similar"]),
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "created_by": createdBy == null
        ? []
        : List<dynamic>.from(createdBy!.map((x) => x.toJson())),
    "episode_run_time": episodeRunTime == null
        ? []
        : List<dynamic>.from(episodeRunTime!.map((x) => x)),
    "first_air_date":
        "${firstAirDate!.year.toString().padLeft(4, '0')}-${firstAirDate!.month.toString().padLeft(2, '0')}-${firstAirDate!.day.toString().padLeft(2, '0')}",
    "genres": genres == null
        ? []
        : List<dynamic>.from(genres.map((x) => x.toJson())),
    "homepage": homepage,
    "id": id,
    "in_production": inProduction,
    "languages": languages == null
        ? []
        : List<dynamic>.from(languages!.map((x) => x)),
    "last_air_date":
        "${lastAirDate!.year.toString().padLeft(4, '0')}-${lastAirDate!.month.toString().padLeft(2, '0')}-${lastAirDate!.day.toString().padLeft(2, '0')}",
    "last_episode_to_air": lastEpisodeToAir?.toJson(),
    "name": name,
    "next_episode_to_air": nextEpisodeToAir?.toJson(),
    "networks": networks == null
        ? []
        : List<dynamic>.from(networks!.map((x) => x.toJson())),
    "number_of_episodes": numberOfEpisodes,
    "number_of_seasons": numberOfSeasons,
    "origin_country": originCountry == null,
    "original_language": originalLanguage,
    "original_name": originalName,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "production_companies": productionCompanies == null
        ? []
        : List<dynamic>.from(productionCompanies!.map((x) => x.toJson())),
    "production_countries": productionCountries == null
        ? []
        : List<dynamic>.from(productionCountries!.map((x) => x.toJson())),
    "spoken_languages": spokenLanguages == null
        ? []
        : List<dynamic>.from(spokenLanguages!.map((x) => x.toJson())),
    "status": status,
    "tagline": tagline,
    "type": type,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "seasons": List<dynamic>.from(seasons.map((x) => x.toJson())),
    "external_ids": externalIds.toJson(),
    "credits": credits?.toJson(),
    "images": images?.toJson(),
    "similar": similar?.toJson(),
  };
}

class CreatedBy {
  final int? id;
  final String? creditId;
  final String? name;
  final String? originalName;
  final int? gender;
  final String? profilePath;

  CreatedBy({
    this.id,
    this.creditId,
    this.name,
    this.originalName,
    this.gender,
    this.profilePath,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) => CreatedBy(
    id: json["id"],
    creditId: json["credit_id"],
    name: json["name"],
    originalName: json["original_name"],
    gender: json["gender"],
    profilePath: json["profile_path"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "credit_id": creditId,
    "name": name,
    "original_name": originalName,
    "gender": gender,
    "profile_path": profilePath,
  };
}

class Episode {
  final int? id;
  final String name;
  final String overview;
  final double? voteAverage;
  final int? voteCount;
  final DateTime? airDate;
  final int episodeNumber;
  final String? episodeType;
  final String? productionCode;
  final int? runtime;
  final int? seasonNumber;
  final int? showId;
  final String? stillPath;

  Episode({
    this.id,
    required this.name,
    required this.overview,
    this.voteAverage,
    this.voteCount,
    this.airDate,
    required this.episodeNumber,
    this.episodeType,
    this.productionCode,
    this.runtime,
    this.seasonNumber,
    this.showId,
    this.stillPath,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json["id"],
    name: json["name"],
    overview: json["overview"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    airDate: DateTime.tryParse(json["air_date"]),
    episodeNumber: json["episode_number"],
    episodeType: json["episode_type"],
    productionCode: json["production_code"],
    runtime: json["runtime"],
    seasonNumber: json["season_number"],
    showId: json["show_id"],
    stillPath: json["still_path"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "overview": overview,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "air_date":
        "${airDate!.year.toString().padLeft(4, '0')}-${airDate!.month.toString().padLeft(2, '0')}-${airDate!.day.toString().padLeft(2, '0')}",
    "episode_number": episodeNumber,
    "episode_type": episodeType,
    "production_code": productionCode,
    "runtime": runtime,
    "season_number": seasonNumber,
    "show_id": showId,
    "still_path": stillPath,
  };
}

class Network {
  final int? id;
  final String? logoPath;
  final String? name;
  final String? originCountry;

  Network({this.id, this.logoPath, this.name, this.originCountry});

  factory Network.fromJson(Map<String, dynamic> json) => Network(
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

class Season {
  final String? id;
  final DateTime? airDate;
  final List<Episode> episodes;
  final String? name;
  final List<Network>? networks;
  final String? overview;
  final String? posterPath;
  final int seasonNumber;
  final double? voteAverage;

  Season({
    this.id,
    this.airDate,
    required this.episodes,
    this.name,
    this.networks,
    this.overview,
    this.posterPath,
    required this.seasonNumber,
    this.voteAverage,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    id: json["_id"],
    airDate: DateTime.tryParse(json["air_date"]),
    episodes: json["episodes"] == null
        ? []
        : List<Episode>.from(json["episodes"]!.map((x) => Episode.fromJson(x))),
    name: json["name"],
    networks: json["networks"] == null
        ? []
        : List<Network>.from(json["networks"]!.map((x) => Network.fromJson(x))),
    overview: json["overview"],
    posterPath: json["poster_path"],
    seasonNumber: json["season_number"],
    voteAverage: json["vote_average"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "air_date":
        "${airDate!.year.toString().padLeft(4, '0')}-${airDate!.month.toString().padLeft(2, '0')}-${airDate!.day.toString().padLeft(2, '0')}",
    "episodes": episodes == null
        ? []
        : List<dynamic>.from(episodes!.map((x) => x.toJson())),
    "name": name,
    "networks": networks == null
        ? []
        : List<dynamic>.from(networks!.map((x) => x.toJson())),
    "overview": overview,
    "poster_path": posterPath,
    "season_number": seasonNumber,
    "vote_average": voteAverage,
  };
}

class SimilarSeries {
  final int? page;
  final List<Result>? results;
  final int? totalPages;
  final int? totalResults;

  SimilarSeries({this.page, this.results, this.totalPages, this.totalResults});

  factory SimilarSeries.fromJson(Map<String, dynamic> json) => SimilarSeries(
    page: json["page"],
    results: json["results"] == null
        ? []
        : List<Result>.from(json["results"]!.map((x) => Result.fromJson(x))),
    totalPages: json["total_pages"],
    totalResults: json["total_results"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "results": results == null
        ? []
        : List<dynamic>.from(results!.map((x) => x.toJson())),
    "total_pages": totalPages,
    "total_results": totalResults,
  };
}

class Result {
  final bool? adult;
  final String? backdropPath;
  final List<int>? genreIds;
  final int id;
  final List<String>? originCountry;
  final String? originalLanguage;
  final String originalName;
  final String? overview;
  final double? popularity;
  final String? posterPath;
  final DateTime? firstAirDate;
  final String name;
  final double? voteAverage;
  final int? voteCount;

  Result({
    this.adult,
    this.backdropPath,
    this.genreIds,
    required this.id,
    this.originCountry,
    this.originalLanguage,
    required this.originalName,
    this.overview,
    this.popularity,
    this.posterPath,
    this.firstAirDate,
    required this.name,
    this.voteAverage,
    this.voteCount,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    adult: json["adult"],
    backdropPath: json["backdrop_path"],
    genreIds: json["genre_ids"] == null
        ? []
        : List<int>.from(json["genre_ids"]!.map((x) => x)),
    id: json["id"],
    originCountry: json["origin_country"] == null
        ? []
        : List<String>.from(json["origin_country"]!.map((x) => x)),
    originalLanguage: json["original_language"],
    originalName: json["original_name"],
    overview: json["overview"],
    popularity: json["popularity"]?.toDouble(),
    posterPath: json["poster_path"],
    firstAirDate: DateTime.tryParse(json["first_air_date"]),
    name: json["name"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "genre_ids": genreIds == null
        ? []
        : List<dynamic>.from(genreIds!.map((x) => x)),
    "id": id,
    "origin_country": originCountry == null
        ? []
        : List<dynamic>.from(originCountry!.map((x) => x)),
    "original_language": originalLanguage,
    "original_name": originalName,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "first_air_date":
        "${firstAirDate!.year.toString().padLeft(4, '0')}-${firstAirDate!.month.toString().padLeft(2, '0')}-${firstAirDate!.day.toString().padLeft(2, '0')}",
    "name": name,
    "vote_average": voteAverage,
    "vote_count": voteCount,
  };
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

class SimilarShows {
  final int? page;
  final List<Result>? results;
  final int? totalPages;
  final int? totalResults;

  SimilarShows({this.page, this.results, this.totalPages, this.totalResults});

  factory SimilarShows.fromJson(Map<String, dynamic> json) => SimilarShows(
    page: json["page"],
    results: json["results"] == null
        ? []
        : List<Result>.from(json["results"]!.map((x) => Result.fromJson(x))),
    totalPages: json["total_pages"],
    totalResults: json["total_results"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "results": results == null
        ? []
        : List<dynamic>.from(results!.map((x) => x.toJson())),
    "total_pages": totalPages,
    "total_results": totalResults,
  };
}
