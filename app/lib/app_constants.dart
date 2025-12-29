import 'package:zxy_app/usecase/resource/models.dart';

enum FilterType { trending, year, featured, topRated, popular }

class Filter {
  final FilterType type;
  final String showValue;
  final List<FilterValue> possibleValues;

  Filter({
    required this.type,
    required this.possibleValues,
    required this.showValue,
  });

  @override
  String toString() {
    return type.toString();
  }
}

class FilterValue {
  final String showValue;
  final String sendValue;

  FilterValue({required this.showValue, required this.sendValue});
  @override
  String toString() {
    return showValue + sendValue;
  }
}

class AppConstants {
  static const String baseUrl = "http://localhost:6969";
  static final String tmdbImageBaseUrl = "https://image.tmdb.org/t/p/";
  static const String tmdbSmallLogo =
      "https://upload.wikimedia.org/wikipedia/commons/8/89/Tmdb.new.logo.svg";
  static late final Map<int, Genre> movieGenre;
  static late final Map<int, Genre> showGenre;

  static final Filter trendingFilter = Filter(
    showValue: "Trending",
    type: FilterType.trending,
    possibleValues: [],
  );
  static final Filter popularFilter = Filter(
    showValue: "Popular",
    type: FilterType.popular,
    possibleValues: AppConstants.movieGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );
  static final Filter featuredFilter = Filter(
    showValue: "Featured",
    type: FilterType.featured,
    possibleValues: AppConstants.movieGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );
  static final Filter topRatedFilter = Filter(
    showValue: "Top Rated",
    type: FilterType.topRated,
    possibleValues: AppConstants.movieGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );

  static final Filter popularFilterShow = Filter(
    showValue: "Popular",
    type: FilterType.popular,
    possibleValues: AppConstants.showGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );
  static final Filter featuredFilterShow = Filter(
    showValue: "Featured",
    type: FilterType.featured,
    possibleValues: AppConstants.showGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );
  static final Filter topRatedFilterShow = Filter(
    showValue: "Top Rated",
    type: FilterType.topRated,
    possibleValues: AppConstants.showGenre.values.map((genre) {
      return FilterValue(showValue: genre.name, sendValue: genre.id.toString());
    }).toList(),
  );
  static final Filter yearFilter = Filter(
    showValue: "By year",
    type: FilterType.year,
    possibleValues: List.generate(5, (index) {
      var val = (DateTime.now().year - index).toString();
      return FilterValue(showValue: val, sendValue: val);
    }),
  );
  static final List<Filter> movieFilters = [
    trendingFilter,
    popularFilter,
    topRatedFilter,
    featuredFilter,
    yearFilter,
  ];

  static final List<Filter> showFilters = [
    trendingFilter,
    popularFilterShow,
    topRatedFilterShow,
    featuredFilterShow,
    yearFilter,
  ];
}

class AppIcons {
  static const String home = "icons/home.svg";
  static const String profile = "icons/profile.svg";
  static const String movie = "icons/movie.svg";
  static const String show = "icons/show.svg";
  static const String settings = "icons/settings.svg";
  static const String play = "icons/play.svg";
}
