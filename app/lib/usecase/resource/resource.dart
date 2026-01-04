import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';

const _baseUrl = AppConstants.baseUrl;
const _movie = "/discover/movies";
const _trendingMovie = "/trending/movies";
const _trendingShow = "/trending/shows";
const _tv = "/discover/shows";

class MediaUsecase {
  String? _readAccessToken;
  late final http.Client _client;

  MediaUsecase() {
    _client = http.Client();
  }

  void setReadAccessToken(String token) {
    _readAccessToken = token;
  }

  Map<String, String> _getHeaders() {
    if (_readAccessToken == null) {
      throw "Token not initialised";
    }
    return {
      "Authorization": "Bearer $_readAccessToken",
      "accept": "application/json",
    };
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> discoverMovies({
    Map<String, String>? filter,
  }) async {
    print(filter);
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
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from Resource api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Resource api";
    }
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
    print(filter);
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
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from Resource api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Resource api";
    }
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
    final res = await _client.get(
      Uri.parse("$_baseUrl/movie/$id?append_to_response=credits"),
      headers: _getHeaders(),
    );
    final resBody = res.body;
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code from Resource ${res.statusCode} $resBody");
      }
      throw "Invalid status code";
    }
    return MovieDetails.fromJson(jsonDecode(resBody));
  }

  Future<SeriesDetails> getSeriesDetails(int id) async {
    final res = await _client.get(
      Uri.parse("$_baseUrl/show/$id?append_to_response=credits"),
      headers: _getHeaders(),
    );
    final resBody = res.body;
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code from Resource ${res.statusCode} $resBody");
      }
      throw "Invalid status code";
    }
    return SeriesDetails.fromJson(jsonDecode(resBody));
  }

  Future<SeasonDetails> getSeasonDetails(int id, int seasonNo) async {
    final res = await _client.get(
      Uri.parse("$_baseUrl/show/$id:$seasonNo?append_to_response=credits"),
      headers: _getHeaders(),
    );
    final resBody = res.body;
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code from Resource ${res.statusCode} $resBody");
      }
      throw "Invalid status code";
    }
    return SeasonDetails.fromJson(jsonDecode(resBody));
  }

  Future<EpisodeDetails> getEpisodeDetails(
    int id,
    int seasonNo,
    int episodeNumber,
  ) async {
    final res = await _client.get(
      Uri.parse(
        "$_baseUrl/show/$id:$seasonNo:$episodeNumber?append_to_response=credits",
      ),
      headers: _getHeaders(),
    );
    final resBody = res.body;
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code from Resource ${res.statusCode} $resBody");
      }
      throw "Invalid status code";
    }
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
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from Trending api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Trending api";
    }
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
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from Trending api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Trending api";
    }
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
    final res = await _client.get(Uri.parse("$_baseUrl/genre"));
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code getting genre ${res.body}");
      }
      throw "Something went wrong";
    }
    return GenreResponse.fromJson(jsonDecode(res.body));
  }

  Future<ImageConfiguation> getConfiguration() async {
    final res = await _client.get(Uri.parse("$_baseUrl/configuration"));
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print("Invalid status code getting genre ${res.body}");
      }
      throw "Something went wrong";
    }
    return ImageConfiguation.fromJson(jsonDecode(res.body)["images"]);
  }

  Future<ZxyPaginatedResponse<ZxyMedia>> searchMovies(
    int page,
    String keyword,
  ) async {
    var url = "$_baseUrl/search/movie?page=$page&keyword=$keyword";
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from search api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Search api";
    }
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
    final response = await _client.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print(
          "Invalid response from search api ${response.statusCode} ${response.body}",
        );
      }
      throw "Invalid response from Search api";
    }
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
