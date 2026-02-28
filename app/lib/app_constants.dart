import 'package:zxy_app/usecase/resource/models.dart';

enum FilterType { trending, year, featured, topRated, popular }

//NOTE: Thanks AI
class LanguageMapper {
  static const Map<String, List<String>> nameToCodes = {
    "Albanian": ["sq", "sqi", "alb"],
    "Arabic": ["ar", "ara"],
    "Armenian": ["hy", "hye", "arm"],
    "Basque": ["eu", "eus", "baq"],
    "Bengali": ["bn", "ben"],
    "Bosnian": ["bs", "bos"],
    "Bulgarian": ["bg", "bul"],
    "Burmese": ["my", "mya", "bur"],
    "Catalan": ["ca", "cat"],
    "Chinese": ["zh", "zho", "chi"],
    "Croatian": ["hr", "hrv", "scr"],
    "Czech": ["cs", "ces", "cze"],
    "Danish": ["da", "dan"],
    "Dutch": ["nl", "nld", "dut"],
    "English": ["en", "eng"],
    "Estonian": ["et", "est"],
    "Finnish": ["fi", "fin"],
    "French": ["fr", "fra", "fre"],
    "Georgian": ["ka", "kat", "geo"],
    "German": ["de", "deu", "ger"],
    "Greek": ["el", "ell", "gre"],
    "Hebrew": ["he", "heb"],
    "Hindi": ["hi", "hin"],
    "Hungarian": ["hu", "hun"],
    "Icelandic": ["is", "isl", "ice"],
    "Indonesian": ["id", "ind"],
    "Italian": ["it", "ita"],
    "Japanese": ["ja", "jpn"],
    "Korean": ["ko", "kor"],
    "Latvian": ["lv", "lav"],
    "Lithuanian": ["lt", "lit"],
    "Macedonian": ["mk", "mkd", "mac"],
    "Malay": ["ms", "msa", "may"],
    "Norwegian": ["no", "nor"],
    "Persian": ["fa", "fas", "per"],
    "Polish": ["pl", "pol"],
    "Portuguese": ["pt", "por"],
    "Romanian": ["ro", "ron", "rum"],
    "Russian": ["ru", "rus"],
    "Serbian": ["sr", "srp", "scc"],
    "Slovak": ["sk", "slk", "slo"],
    "Slovenian": ["sl", "slv"],
    "Spanish": ["es", "spa"],
    "Swahili": ["sw", "swa"],
    "Swedish": ["sv", "swe"],
    "Thai": ["th", "tha"],
    "Tibetan": ["bo", "bod", "tib"],
    "Turkish": ["tr", "tur"],
    "Ukrainian": ["uk", "ukr"],
    "Urdu": ["ur", "urd"],
    "Vietnamese": ["vi", "vie"],
    "Welsh": ["cy", "cym", "wel"],
  };

  static const String defaultLang = "English";

  static final Map<String, String> _codeToName = _generateCodeToName();

  static Map<String, String> _generateCodeToName() {
    final Map<String, String> result = {};
    nameToCodes.forEach((name, codes) {
      for (var code in codes) {
        result[code.toLowerCase()] = name;
      }
    });
    return result;
  }

  static String? getNameFromCode(String code) {
    return _codeToName[code.toLowerCase().trim()];
  }

  static List<String>? getCodesFromName(String name) {
    return nameToCodes[name];
  }
}

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
  // static const String baseUrl = "http://localhost:6969";
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

  static const Map<String, dynamic> resolutionMap = {
    "2160p": null,
    "1080p": null,
    "720p": null,
  };

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
