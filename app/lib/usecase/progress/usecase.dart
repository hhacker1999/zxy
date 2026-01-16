import 'dart:convert';

import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/progress/model.dart';

class ProgressUsecase {
  final HttpService _service;

  const ProgressUsecase({required HttpService service}) : _service = service;

  Future<List<WatchProgress>> getContinueWatching() async {
    final res = await _service.get(
      Uri.parse("${AppConstants.baseUrl}/continue_watching"),
      auth: RequestAuth.profile,
    );
    if (res.body.isEmpty || res.body == "null") {
      return List<WatchProgress>.empty();
    }
    final List<Map<String, dynamic>> parsed = List.from(jsonDecode(res.body));
    return parsed.map((e) => WatchProgress.fromJson(e)).toList();
  }

  Future<WatchProgress?> getMovieProgress(String movieId) async {
    final res = await _service.get(
      Uri.parse("${AppConstants.baseUrl}/movie/$movieId/progress"),
      auth: RequestAuth.profile,
    );
    if (res.body.isEmpty) {
      return null;
    }

    return WatchProgress.fromJson(jsonDecode(res.body));
  }

  Future<List<WatchProgress>> getProgressShow(String showId) async {
    final res = await _service.get(
      Uri.parse("${AppConstants.baseUrl}/show/$showId/progress"),
      auth: RequestAuth.profile,
    );
    if (res.body.isEmpty || res.body == "null") {
      return List<WatchProgress>.empty();
    }
    final List<Map<String, dynamic>> parsed = List.from(jsonDecode(res.body));
    return parsed.map((e) => WatchProgress.fromJson(e)).toList();
  }

  Future<void> updateWatchProgressMovie(String mediaId, double progress) {
    return _service.post(
      Uri.parse("${AppConstants.baseUrl}/movie/update_progress"),
      auth: RequestAuth.profile,
      body: {"movie_id": mediaId, "progress": progress},
    );
  }

  Future<void> updateWatchProgressShow(
    String mediaId,
    int season,
    int episode,
    double progress,
  ) {
    return _service.post(
      Uri.parse("${AppConstants.baseUrl}/show/update_progress"),
      auth: RequestAuth.profile,
      body: {
        "show_id": mediaId.toString(),
        "progress": progress,
        "episode": episode,
        "season": season,
      },
    );
  }
}
