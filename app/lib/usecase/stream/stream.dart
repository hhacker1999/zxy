import 'dart:convert';

import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/stream/model.dart';

class StreamUsecase {
  static const String _streamPath = "/streams";
  final HttpService _httpService;

  const StreamUsecase(this._httpService);

  Future<List<StreamItem>> getMovieStreams(String id) async {
    final response = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}$_streamPath?type=movie&id=$id"),
      auth: RequestAuth.profile,
    );
    return List<Map<String, dynamic>>.from(
      json.decode(response.body),
    ).map((e) => StreamItem.fromJson(e)).toList();
  }

  Future<List<StreamItem>> getSeriesStreams(
    String id,
    int season,
    int episode,
  ) async {
    final response = await _httpService.get(
      Uri.parse(
        "${AppConstants.baseUrl}$_streamPath?type=series&id=$id&season=$season&episode=$episode",
      ),
      auth: RequestAuth.profile,
    );
    return List<Map<String, dynamic>>.from(
      json.decode(response.body),
    ).map((e) => StreamItem.fromJson(e)).toList();
  }
}
