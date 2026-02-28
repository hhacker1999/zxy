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
  final bool isPinProtected;
  final String debridType;
  final bool isAdmin;
  final List<ProfileLibraryItem> libraryItems;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.isPinProtected,
    required this.debridType,
    required this.isAdmin,
    required this.libraryItems,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json["id"],
    name: json["name"],
    isPinProtected: json["is_pin_protected"],
    createdAt: DateTime.parse(json["created_at"]),
    debridType: json["debrid_type"],
    isAdmin: json["is_admin"],
    libraryItems: json["library_items"] != null
        ? List<ProfileLibraryItem>.from(
            json["library_items"].map((x) => ProfileLibraryItem.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "is_pin_protected": isPinProtected,
    "debrid_type": debridType,
    "is_admin": isAdmin,
    "library_items": List<dynamic>.from(libraryItems.map((x) => x.toJson())),
  };
}

class ProfileLibraryItem {
  final String name;
  final LibraryFilter filter;

  late String id;

  ProfileLibraryItem({required this.name, required this.filter})
    : id = DateTime.now().microsecondsSinceEpoch.toString();

  factory ProfileLibraryItem.fromJson(Map<String, dynamic> json) =>
      ProfileLibraryItem(
        name: json["name"],
        filter: LibraryFilter.fromJson(json["filter"]),
      );

  Map<String, dynamic> toJson() => {"name": name, "filter": filter.toJson()};

  ProfileLibraryItem copyWith({String? name, LibraryFilter? filter}) =>
      ProfileLibraryItem(
        name: name ?? this.name,
        filter: filter ?? this.filter,
      );
}

class LibraryFilter {
  final bool isMovie;
  final bool isTrending;
  final bool thisWeek;
  final bool thisMonth;
  final List<int> years;
  final bool isFirstAir;
  final int imdbRating;
  final String language;
  final String sort;
  final bool isAsc;
  final int items;
  final List<int> includedGenres;
  final List<int> excludedGenres;
  final int page;
  final int minVotes;

  LibraryFilter({
    required this.isMovie,
    required this.isTrending,
    required this.thisWeek,
    required this.thisMonth,
    required this.years,
    required this.isFirstAir,
    required this.minVotes,
    required this.imdbRating,
    required this.language,
    required this.sort,
    required this.isAsc,
    required this.items,
    required this.includedGenres,
    required this.excludedGenres,
    required this.page,
  });

  factory LibraryFilter.fromJson(Map<String, dynamic> json) => LibraryFilter(
    isMovie: json["is_movie"],
    isTrending: json["is_trending"],
    thisWeek: json["this_week"],
    thisMonth: json["this_month"],
    years: List<int>.from(json["years"].map((x) => x)),
    isFirstAir: json["is_first_air"],
    imdbRating: json["imdb_rating"],
    language: json["language"],
    sort: json["sort"],
    isAsc: json["is_asc"],
    items: json["items"],
    includedGenres: List<int>.from(json["included_genres"].map((x) => x)),
    excludedGenres: List<int>.from(json["excluded_genres"].map((x) => x)),
    page: json["page"],
    minVotes: json["min_votes"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "is_movie": isMovie,
    "is_trending": isTrending,
    "this_week": thisWeek,
    "this_month": thisMonth,
    "years": List<dynamic>.from(years.map((x) => x)),
    "is_first_air": isFirstAir,
    "imdb_rating": imdbRating,
    "language": language,
    "sort": sort,
    "is_asc": isAsc,
    "items": items,
    "included_genres": List<dynamic>.from(includedGenres.map((x) => x)),
    "excluded_genres": List<dynamic>.from(excludedGenres.map((x) => x)),
    "page": page,
    "min_votes": minVotes,
  };

  factory LibraryFilter.defaultFilter() => LibraryFilter(
    isMovie: true,
    thisWeek: false,
    thisMonth: false,
    years: [],
    isFirstAir: true,
    imdbRating: 0,
    language: '',
    sort: 'popularity',
    isAsc: false,
    items: 20,
    includedGenres: [],
    excludedGenres: [],
    isTrending: false,
    page: 1,
    minVotes: 0,
  );

  LibraryFilter copyWith({
    bool? isMovie,
    bool? isTrending,
    bool? thisWeek,
    bool? thisMonth,
    List<int>? years,
    bool? isFirstAir,
    int? imdbRating,
    String? language,
    String? sort,
    bool? isAsc,
    int? items,
    List<int>? includedGenres,
    List<int>? excludedGenres,
    int? page,
    int? minVotes,
  }) => LibraryFilter(
    isTrending: isTrending ?? this.isTrending,
    isMovie: isMovie ?? this.isMovie,
    thisWeek: thisWeek ?? this.thisWeek,
    thisMonth: thisMonth ?? this.thisMonth,
    years: years ?? this.years,
    isFirstAir: isFirstAir ?? this.isFirstAir,
    imdbRating: imdbRating ?? this.imdbRating,
    language: language ?? this.language,
    sort: sort ?? this.sort,
    isAsc: isAsc ?? this.isAsc,
    items: items ?? this.items,
    includedGenres: includedGenres ?? this.includedGenres,
    excludedGenres: excludedGenres ?? this.excludedGenres,
    page: page ?? this.page,
    minVotes: minVotes ?? this.minVotes,
  );
}
