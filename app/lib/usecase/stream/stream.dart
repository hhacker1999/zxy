import 'dart:convert';

import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/stream/model.dart';

class StreamUsecase {
  static const String _streamPath = "/v2/streams";
  final HttpService _httpService;

  const StreamUsecase(this._httpService);

  Future<ZxyStreamResponse> getMovieStreams(String id) async {
    final response = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}$_streamPath?type=movie&id=$id"),
      auth: RequestAuth.profile,
    );
    final decoded = json.decode(response.body);
    if (decoded == null) {
      return ZxyStreamResponse(uhd: [], fhd: [], hd: []);
    }
    return ZxyStreamResponse.fromJson(decoded);
  }

  Future<ZxyStreamResponse> getSeriesStreams(
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
    final decoded = json.decode(response.body);
    if (decoded == null) {
      return ZxyStreamResponse(uhd: [], fhd: [], hd: []);
    }
    return ZxyStreamResponse.fromJson(decoded);
  }

  Future<String> getStreamUrl(String tempUrl) async {
    final response = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}/stream_url?temp_url=$tempUrl"),
      auth: RequestAuth.profile,
    );
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final url = decoded["url"];
      if (url != null) {
        return url;
      }
    }

    throw HttpSomethingWentWrong();
  }
}
