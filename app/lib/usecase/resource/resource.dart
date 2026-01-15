import 'dart:convert';

import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';

const _baseUrl = AppConstants.baseUrl;
const _movie = "/discover/movies";
const _trendingMovie = "/trending/movies";
const _trendingShow = "/trending/shows";
const _tv = "/discover/shows";

class MediaUsecase {
  final HttpService _httpService;

  MediaUsecase(this._httpService);

  Future<ZxyPaginatedResponse<ZxyMedia>> discoverMovies({
    Map<String, String>? filter,
  }) async {
    var url = _baseUrl + _movie;
    if (filter != null) {
      var entries = filter.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        var element = entries[i];
        if (i == 0) {
          url += "?";
        } else {
          url += "&";
        }
        url += "${element.key}=${element.value}";
      }
    }
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.movie));
      }
      return temp;
    });

    return finalResult;
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> discoverShows({
    Map<String, String>? filter,
  }) async {
    var url = _baseUrl + _tv;
    if (filter != null) {
      var entries = filter.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        var element = entries[i];
        if (i == 0) {
          url += "?";
        } else {
          url += "&";
        }
        url += "${element.key}=${element.value}";
      }
    }
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.shows));
      }
      return temp;
    });

    return finalResult;
  }

  Future<MovieDetails> getMovieDetails(int id) async {
    final res = await _httpService.get(
      Uri.parse("$_baseUrl/movie/$id?append_to_response=credits"),
      auth: RequestAuth.profile,
    );
    final resBody = res.body;
    return MovieDetails.fromJson(jsonDecode(resBody));
  }

  Future<SeriesDetails> getSeriesDetails(int id) async {
    final res = await _httpService.get(
      Uri.parse("$_baseUrl/show/$id?append_to_response=credits"),
      auth: RequestAuth.profile,
    );
    final resBody = res.body;
    return SeriesDetails.fromJson(jsonDecode(resBody));
  }

  Future<SeasonDetails> getSeasonDetails(int id, int seasonNo) async {
    final res = await _httpService.get(
      Uri.parse("$_baseUrl/show/$id:$seasonNo?append_to_response=credits"),
      auth: RequestAuth.profile,
    );
    final resBody = res.body;
    return SeasonDetails.fromJson(jsonDecode(resBody));
  }

  Future<EpisodeDetails> getEpisodeDetails(
    int id,
    int seasonNo,
    int episodeNumber,
  ) async {
    final res = await _httpService.get(
      Uri.parse(
        "$_baseUrl/show/$id:$seasonNo:$episodeNumber?append_to_response=credits",
      ),
      auth: RequestAuth.profile,
    );
    final resBody = res.body;
    return EpisodeDetails.fromJson(jsonDecode(resBody));
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> getTrendingMovies({
    Map<String, String>? filter,
  }) async {
    var url = _baseUrl + _trendingMovie;
    if (filter != null) {
      var entries = filter.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        var element = entries[i];
        if (i == 0) {
          url += "?";
        } else {
          url += "&";
        }
        url += "${element.key}=${element.value}";
      }
    }
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.movie));
      }
      return temp;
    });

    return finalResult;
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> getTrendingShows({
    Map<String, String>? filter,
  }) async {
    var url = _baseUrl + _trendingShow;
    if (filter != null) {
      var entries = filter.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        var element = entries[i];
        if (i == 0) {
          url += "?";
        } else {
          url += "&";
        }
        url += "${element.key}=${element.value}";
      }
    }
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.shows));
      }
      return temp;
    });

    return finalResult;
  }

  Future<GenreResponse> getGenre() async {
    final res = await _httpService.get(
      Uri.parse("$_baseUrl/genre"),
      auth: RequestAuth.profile,
    );
    return GenreResponse.fromJson(jsonDecode(res.body));
  }

  Future<ImageConfiguation> getConfiguration() async {
    final res = await _httpService.get(
      Uri.parse("$_baseUrl/configuration"),
      auth: RequestAuth.profile,
    );
    return ImageConfiguation.fromJson(jsonDecode(res.body)["images"]);
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> searchMovies(
    int page,
    String keyword,
  ) async {
    var url = "$_baseUrl/search/movie?page=$page&keyword=$keyword";
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.movie));
      }
      return temp;
    });

    return finalResult;
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> searchShows(
    int page,
    String keyword,
  ) async {
    var url = "$_baseUrl/search/show?page=$page&keyword=$keyword";
    final response = await _httpService.get(
      Uri.parse(url),
      auth: RequestAuth.profile,
    );
    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final finalResult = ZxyPaginatedResponse<ZxyMedia>.fromJson(responseMap, (
      results,
    ) {
      final List<ZxyMedia> temp = [];
      for (var item in results) {
        temp.add(ZxyMedia.fromJson(item, ZxyMediaType.shows));
      }
      return temp;
    });

    return finalResult;
  }
}
