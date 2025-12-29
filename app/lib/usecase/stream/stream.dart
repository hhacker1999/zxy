import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/usecase/stream/model.dart';

class StreamUsecase {
  static const String _streamPath = "/streams";
  late final http.Client _client;

  StreamUsecase() {
    _client = http.Client();
  }

  Future<List<StreamItem>> getMovieStreams(int id) async {
    final response = await _client.get(
      Uri.parse("${AppConstants.baseUrl}$_streamPath?type=movie&id=$id"),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body),
      ).map((e) => StreamItem.fromJson(e)).toList();
    } else {
      if (kDebugMode) {
        print("Error getting streams ${response.body}");
      }
      throw Exception("Failed to load streams");
    }
  }

  Future<List<StreamItem>> getSeriesStreams(
    int id,
    int season,
    int episode,
  ) async {
    final response = await _client.get(
      Uri.parse(
        "${AppConstants.baseUrl}$_streamPath?type=series&id=$id&season=$season&episode=$episode",
      ),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        json.decode(response.body),
      ).map((e) => StreamItem.fromJson(e)).toList();
    } else {
      if (kDebugMode) {
        print("Error getting streams ${response.body}");
      }
      throw Exception("Failed to load streams");
    }
  }
}
