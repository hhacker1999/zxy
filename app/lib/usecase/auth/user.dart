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

class Service {
  String id;
  String name;
  String inputType;
  bool enabled;

  Service({
    required this.id,
    required this.name,
    required this.inputType,
    required this.enabled,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json["id"],
    name: json["name"],
    inputType: json["input_type"],
    enabled: json["enabled"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "input_type": inputType,
    "enabled": enabled,
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
  final DateTime? traktExpiry;
  final bool isTraktValid;
  final List<ProfileTraktLists> profileTraktLists;
  final List<Service> services;

  Profile({
    required this.id,
    required this.name,
    required this.isPinProtected,
    required this.debridType,
    required this.isAdmin,
    required this.libraryItems,
    required this.createdAt,
    this.traktExpiry,
    required this.isTraktValid,
    required this.profileTraktLists,
    required this.services,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json["id"],
    name: json["name"],
    isPinProtected: json["is_pin_protected"],
    profileTraktLists: json["trakt_lists"] != null
        ? List<ProfileTraktLists>.from(
            json["trakt_lists"].map((x) => ProfileTraktLists.fromJson(x)),
          )
        : [],
    traktExpiry: json["trakt_expiry"] != null
        ? DateTime.tryParse(json["trakt_expiry"])
        : null,
    isTraktValid: json["trakt_valid"],
    createdAt: DateTime.parse(json["created_at"]),
    debridType: json["debrid_type"],
    isAdmin: json["is_admin"],
    services: json["services"] != null
        ? List<Service>.from(json["services"].map((x) => Service.fromJson(x)))
        : [],
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

class ProfileTraktLists {
  final String name;
  final String description;
  final Ids ids;
  final String privacy;

  ProfileTraktLists({
    required this.name,
    required this.description,
    required this.ids,
    required this.privacy,
  });

  factory ProfileTraktLists.fromJson(Map<String, dynamic> json) =>
      ProfileTraktLists(
        name: json["name"],
        description: json["description"],
        ids: Ids.fromJson(json["ids"]),
        privacy: json["privacy"],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
    "description": description,
    "ids": ids.toJson(),
    "privacy": privacy,
  };
}

class Ids {
  final int trakt;

  Ids({required this.trakt});

  factory Ids.fromJson(Map<String, dynamic> json) => Ids(trakt: json["trakt"]);

  Map<String, dynamic> toJson() => {"trakt": trakt};
}

class ProfileLibraryItem {
  final String name;
  final LibraryFilter filter;

  late String id;

  ProfileLibraryItem({required this.name, required this.filter})
    : id = DateTime.now().microsecondsSinceEpoch.toString();

  factory ProfileLibraryItem.fromJson(Map<String, dynamic> json) {
    return ProfileLibraryItem(
      name: json["name"],
      filter: LibraryFilter.fromJson(json["filter"]),
    );
  }

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
  final String type;
  final String traktId;

  LibraryFilter({
    required this.isMovie,
    required this.type,
    required this.traktId,
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

  LibraryFilter copyWith({
    bool? isMovie,
    List<int>? includedGenres,
    int? items,
    bool? isAsc,
    List<int>? excludedGenres,
    int? minVotes,
    int? page,
    String? type,
    String? sort,
    int? imdbRating,
    bool? thisWeek,
    bool? isTrending,
    String? language,
    bool? thisMonth,
    bool? isFirstAir,
    List<int>? years,
    String? traktId,
  }) {
    return LibraryFilter(
      isMovie: isMovie ?? this.isMovie,
      includedGenres: includedGenres ?? this.includedGenres,
      items: items ?? this.items,
      isAsc: isAsc ?? this.isAsc,
      excludedGenres: excludedGenres ?? this.excludedGenres,
      minVotes: minVotes ?? this.minVotes,
      page: page ?? this.page,
      type: type ?? this.type,
      sort: sort ?? this.sort,
      imdbRating: imdbRating ?? this.imdbRating,
      thisWeek: thisWeek ?? this.thisWeek,
      isTrending: isTrending ?? this.isTrending,
      language: language ?? this.language,
      thisMonth: thisMonth ?? this.thisMonth,
      isFirstAir: isFirstAir ?? this.isFirstAir,
      years: years ?? this.years,
      traktId: traktId ?? this.traktId,
    );
  }

  factory LibraryFilter.fromJson(Map<String, dynamic> json) => LibraryFilter(
    isMovie: json["is_movie"],
    isTrending: json["is_trending"],
    traktId: json["trakt_url"],
    type: json["type"],
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
    "type": type,
    "trakt_url": traktId,
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
    type: "internal",
    traktId: "",
    isMovie: true,
    thisWeek: false,
    thisMonth: false,
    years: [],
    isFirstAir: true,
    imdbRating: 0,
    language: '',
    sort: 'popularity',
    isAsc: false,
    items: 15,
    includedGenres: [],
    excludedGenres: [],
    isTrending: false,
    page: 1,
    minVotes: 0,
  );
}
