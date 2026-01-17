import 'package:zxy_app/usecase/resource/models.dart';

class MovieDetails {
  final bool? adult;
  final ExternalIds externalIds;
  final String? backdropPath;
  final BelongsToCollection? belongsToCollection;
  final Collection? collection;
  final int? budget;
  final Credits? credits;
  final List<Genre>? genres;
  final String? homepage;
  final int id;
  final String imdbId;
  final List<String>? originCountry;
  final String? originalLanguage;
  final String originalTitle;
  final String overview;
  final double? popularity;
  final String posterPath;
  final List<ProductionCompany>? productionCompanies;
  final List<ProductionCountry>? productionCountries;
  final DateTime releaseDate;
  final int? revenue;
  final int runtime;
  final List<SpokenLanguage>? spokenLanguages;
  final String? status;
  final String? tagline;
  final String title;
  final bool? video;
  final double voteAverage;
  final int? voteCount;
  final Images? images;
  final SimilarMovies? similar;

  MovieDetails({
    this.adult,
    this.backdropPath,
    this.credits,
    this.belongsToCollection,
    this.collection,
    this.budget,
    this.genres,
    this.homepage,
    required this.externalIds,
    required this.id,
    required this.imdbId,
    this.originCountry,
    this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    this.popularity,
    required this.posterPath,
    this.productionCompanies,
    this.productionCountries,
    required this.releaseDate,
    this.revenue,
    required this.runtime,
    this.spokenLanguages,
    this.status,
    this.tagline,
    required this.title,
    this.video,
    required this.voteAverage,
    this.voteCount,
    this.images,
    this.similar,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) => MovieDetails(
    adult: json["adult"],
    backdropPath: json["backdrop_path"],
    belongsToCollection: json["belongs_to_collection"] == null
        ? null
        : BelongsToCollection.fromJson(json["belongs_to_collection"]),
    collection: json["collection"] == null
        ? null
        : Collection.fromJson(json["collection"]),
    budget: json["budget"],
    externalIds: ExternalIds.fromJson(json["external_ids"]),
    genres: json["genres"] == null
        ? []
        : List<Genre>.from(json["genres"]!.map((x) => Genre.fromJson(x))),
    homepage: json["homepage"],
    id: json["id"],
    imdbId: json["imdb_id"],
    originCountry: json["origin_country"] == null
        ? []
        : List<String>.from(json["origin_country"]!.map((x) => x)),
    originalLanguage: json["original_language"],
    originalTitle: json["original_title"],
    overview: json["overview"],
    popularity: json["popularity"]?.toDouble(),
    posterPath: json["poster_path"],
    productionCompanies: json["production_companies"] == null
        ? []
        : List<ProductionCompany>.from(
            json["production_companies"]!.map(
              (x) => ProductionCompany.fromJson(x),
            ),
          ),
    productionCountries: json["production_countries"] == null
        ? []
        : List<ProductionCountry>.from(
            json["production_countries"]!.map(
              (x) => ProductionCountry.fromJson(x),
            ),
          ),
    releaseDate: DateTime.parse(json["release_date"]),
    revenue: json["revenue"],
    runtime: json["runtime"],
    spokenLanguages: json["spoken_languages"] == null
        ? []
        : List<SpokenLanguage>.from(
            json["spoken_languages"]!.map((x) => SpokenLanguage.fromJson(x)),
          ),
    credits: json["credits"] == null ? null : Credits.fromJson(json["credits"]),
    status: json["status"],
    tagline: json["tagline"],
    title: json["title"],
    video: json["video"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    images: json["images"] == null ? null : Images.fromJson(json["images"]),
    similar: json["similar"] == null
        ? null
        : SimilarMovies.fromJson(json["similar"]),
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "belongs_to_collection": belongsToCollection?.toJson(),
    "collection": collection?.toJson(),
    "budget": budget,
    "genres": genres == null
        ? []
        : List<dynamic>.from(genres!.map((x) => x.toJson())),
    "homepage": homepage,
    "id": id,
    "imdb_id": imdbId,
    "origin_country": originCountry == null
        ? []
        : List<dynamic>.from(originCountry!.map((x) => x)),
    "original_language": [originalLanguage],
    "original_title": originalTitle,
    "overview": overview,
    "popularity": popularity,
    "poster_path": posterPath,
    "production_companies": productionCompanies == null
        ? []
        : List<dynamic>.from(productionCompanies!.map((x) => x.toJson())),
    "production_countries": productionCountries == null
        ? []
        : List<dynamic>.from(productionCountries!.map((x) => x.toJson())),
    "release_date":
        "${releaseDate.year.toString().padLeft(4, '0')}-${releaseDate.month.toString().padLeft(2, '0')}-${releaseDate.day.toString().padLeft(2, '0')}",
    "revenue": revenue,
    "runtime": runtime,
    "spoken_languages": spokenLanguages,
    "status": status,
    "tagline": tagline,
    "title": title,
    "video": video,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "images": images?.toJson(),
    "similar": similar?.toJson(),
  };
}

class BelongsToCollection {
  final int? id;
  final String? name;
  final String? posterPath;
  final String? backdropPath;

  BelongsToCollection({this.id, this.name, this.posterPath, this.backdropPath});

  factory BelongsToCollection.fromJson(Map<String, dynamic> json) =>
      BelongsToCollection(
        id: json["id"],
        name: json["name"],
        posterPath: json["poster_path"],
        backdropPath: json["backdrop_path"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "poster_path": posterPath,
    "backdrop_path": backdropPath,
  };
}

class Collection {
  final int id;
  final String name;
  final String? originalLanguage;
  final String? originalName;
  final String? overview;
  final String posterPath;
  final String? backdropPath;
  final List<Part> parts;

  Collection({
    required this.id,
    required this.name,
    this.originalLanguage,
    this.originalName,
    this.overview,
    required this.posterPath,
    this.backdropPath,
    required this.parts,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json["id"],
    name: json["name"],
    originalLanguage: json["original_language"],
    originalName: json["original_name"],
    overview: json["overview"],
    posterPath: json["poster_path"],
    backdropPath: json["backdrop_path"],
    parts: json["parts"] == null
        ? []
        : List<Part>.from(json["parts"]!.map((x) => Part.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "original_language": originalLanguage,
    "original_name": originalName,
    "overview": overview,
    "poster_path": posterPath,
    "backdrop_path": backdropPath,
    "parts": parts == null
        ? []
        : List<dynamic>.from(parts!.map((x) => x.toJson())),
  };
}

class Part {
  final bool? adult;
  final String? backdropPath;
  final int id;
  final String? name;
  final String? originalName;
  final String? overview;
  final String posterPath;
  final String? mediaType;
  final String? originalLanguage;
  final List<int>? genreIds;
  final double? popularity;
  final DateTime? releaseDate;
  final bool? video;
  final double? voteAverage;
  final int? voteCount;
  final String? originalTitle;
  final String? title;

  Part({
    this.adult,
    this.backdropPath,
    required this.id,
    this.name,
    this.originalName,
    this.overview,
    required this.posterPath,
    this.mediaType,
    this.originalLanguage,
    this.genreIds,
    this.popularity,
    this.releaseDate,
    this.video,
    this.voteAverage,
    this.voteCount,
    this.originalTitle,
    this.title,
  });

  factory Part.fromJson(Map<String, dynamic> json) => Part(
    adult: json["adult"],
    backdropPath: json["backdrop_path"],
    id: json["id"],
    name: json["name"],
    originalName: json["original_name"],
    overview: json["overview"],
    posterPath: json["poster_path"],
    mediaType: json["media_type"],
    originalLanguage: json["original_language"]!,
    genreIds: json["genre_ids"] == null
        ? []
        : List<int>.from(json["genre_ids"]!.map((x) => x)),
    popularity: json["popularity"]?.toDouble(),
    releaseDate: DateTime.tryParse(json["release_date"]),
    video: json["video"],
    voteAverage: json["vote_average"]?.toDouble(),
    voteCount: json["vote_count"],
    originalTitle: json["original_title"],
    title: json["title"],
  );

  Map<String, dynamic> toJson() => {
    "adult": adult,
    "backdrop_path": backdropPath,
    "id": id,
    "name": name,
    "original_name": originalName,
    "overview": overview,
    "poster_path": posterPath,
    "media_type": mediaType,
    "original_language": originalLanguage,
    "genre_ids": genreIds == null
        ? []
        : List<dynamic>.from(genreIds!.map((x) => x)),
    "popularity": popularity,
    "release_date":
        "${releaseDate!.year.toString().padLeft(4, '0')}-${releaseDate!.month.toString().padLeft(2, '0')}-${releaseDate!.day.toString().padLeft(2, '0')}",
    "video": video,
    "vote_average": voteAverage,
    "vote_count": voteCount,
    "original_title": originalTitle,
    "title": title,
  };
}

class SimilarMovies {
  final int? page;
  final List<Part> results;
  final int? totalPages;
  final int? totalResults;

  SimilarMovies({
    this.page,
    required this.results,
    this.totalPages,
    this.totalResults,
  });

  factory SimilarMovies.fromJson(Map<String, dynamic> json) => SimilarMovies(
    page: json["page"],
    results: json["results"] == null
        ? []
        : List<Part>.from(json["results"]!.map((x) => Part.fromJson(x))),
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
