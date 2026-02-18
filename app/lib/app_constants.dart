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
  // static const String baseUrl = "http://192.168.1.14:6969";
  static const String baseUrl = "https://zxyapi.tooharsh.co.in";
  // static const String baseUrl = "http://10.8.0.1:6969";
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

  static const Map<String, String> isoLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'ro': 'Romanian',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'hi': 'Hindi',
    'ar': 'Arabic',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'pl': 'Polish',
    'vi': 'Vietnamese',
    'uk': 'Ukranian',
  };

  static const Map<String, String> iso6392Languages = {
    'eng': 'English',
    'fre': 'French',
    'deu': 'German',
    'ger': 'German',
    'zho': 'Chinese',
    'spa': 'Spanish',
    'ita': 'Italian',
    'jpn': 'Japanese',
    'kor': 'Korean',
    'rus': 'Russian',
    'por': 'Portuguese',
    'ara': 'Arabic',
    'hin': 'Hindi',
    'tur': 'Turkish',
    'dut': 'Dutch',
    'nld': 'Dutch',
    'swe': 'Swedish',
    'nor': 'Norwegian',
    'dan': 'Danish',
    'fin': 'Finnish',
    'pol': 'Polish',
    'vie': 'Vietnamese',
    'ind': 'Indonesian',
    'tha': 'Thai',
    'ces': 'Czech',
    'ell': 'Greek',
    'hun': 'Hungarian',
    'haw': 'Hawaiian',
    'yue': 'Cantonese',
    'fil': 'Filipino',
    'ukr': 'Ukranian',
    'rum': 'Romanian',
    'ice': 'Interpreno',
    'kan': 'Kannada',
    'mar': 'Marathi',
    'tam': 'Tamil',
    'ben': 'Bengali',
    'mal': 'Malyalam',
    'tel': 'Telugu',
  };
  static late ImageConfiguation imageConfig;
}

class AppIcons {
  static const String home = "icons/home.svg";
  static const String profile = "icons/profile.svg";
  static const String movie = "icons/movie.svg";
  static const String search = "icons/search.svg";
  static const String show = "icons/show.svg";
  static const String settings = "icons/settings.svg";
  static const String play = "icons/play.svg";
  static const String image = "icons/image.svg";
  static const String logo = "icons/logo.png";
  static const String imdb = "icons/imdb.svg";
  static const String tmdb = "icons/tmdb.svg";
  static const String loading = "icons/loading.json";
  static const String uhd = "icons/4k.svg";
  static const String fhd = "icons/hd.svg";
  static const String hdr = "icons/hdr.svg";
}
