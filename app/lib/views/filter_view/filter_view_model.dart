import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';

enum ZxyMediaType { movie, series }

class FilterViewModel {
  final MediaUsecase mediaUc;
  late final ZxyMediaType _type;
  int _currentPage = 0;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  late final ValueNotifier<(Filter, FilterValue?)> cFilter;

  late final ValueNotifier<List<ZxyMedia>> mediaItems;
  late final List<Filter> filters;
  final ValueNotifier<ZxyMedia?> selectedItem = ValueNotifier(null);

  final ValueNotifier<bool> loading = ValueNotifier(false);

  FilterViewModel({
    required ZxyMediaType type,
    required this.mediaUc,
    Filter? baseFilter,
  }) {
    _type = type;
    mediaItems = ValueNotifier(List.empty(growable: true));
    cFilter = ValueNotifier((baseFilter ?? AppConstants.trendingFilter, null));
    filters = _type == ZxyMediaType.movie
        ? AppConstants.movieFilters
        : AppConstants.showFilters;
  }

  void onMainFilterChange(String value) {
    if (cFilter.value.$1.type.toString() == value) {
      return;
    }

    late final Filter filter;
    for (var element in filters) {
      if (element.type.toString() == value) {
        filter = element;
      }
    }

    cFilter.value = (
      filter,
      filter.type == FilterType.year ? filter.possibleValues.first : null,
    );
    _currentPage = 0;
    mediaItems.value = List.empty(growable: true);
    loadItems();
  }

  void onSecondaryFilterChange(String value) {
    FilterValue? val;
    final index = cFilter.value.$1.possibleValues.indexWhere((ele) {
      return ele.sendValue == value;
    });
    if (index != -1) {
      val = cFilter.value.$1.possibleValues[index];
    }
    if (cFilter.value.$2 == val) {
      return;
    }

    cFilter.value = (cFilter.value.$1, val);
    _currentPage = 0;
    mediaItems.value = List.empty(growable: true);
    loadItems();
    return;
  }

  Future<void> loadItems() async {
    if (loading.value) {
      return;
    }

    try {
      loading.value = true;
      late final ZxyPaginatedResponse<ZxyMedia> res;
      final mapFilter = {"page": "${_currentPage + 1}"};
      if (_type == ZxyMediaType.movie) {
        final filter = cFilter.value;
        if (filter.$1.type == FilterType.trending) {
          res = await mediaUc.getTrendingMovies(filter: mapFilter);
        } else {
          if (filter.$2 != null) {
            if (filter.$1.type == FilterType.year) {
              var yearStr = filter.$2!.sendValue;
              var year = int.parse(yearStr);
              final DateTime lte = yearStr == DateTime.now().year.toString()
                  ? DateTime.now()
                  : DateTime(year, 12, 31, 23, 59);
              final DateTime gte = DateTime(year);
              mapFilter["primary_release_date.lte"] = _formatter.format(lte);
              mapFilter["primary_release_date.gte"] = _formatter.format(gte);
              mapFilter["sort_by"] = "primary_release_date.desc";
            } else {
              mapFilter["with_genres"] = filter.$2!.sendValue;
            }
          }
          if (filter.$1.type == FilterType.popular) {
            mapFilter["sort_by"] = "popularity.desc";
          }
          if (filter.$1.type == FilterType.topRated) {
            mapFilter["sort_by"] = "vote_average.desc";
            mapFilter["without_genres"] = "99,10755";
            mapFilter["vote_count.gte"] = "200";
          }
          res = await mediaUc.discoverMovies(filter: mapFilter);
        }
      } else {
        final filter = cFilter.value;
        if (filter.$1.type == FilterType.trending) {
          res = await mediaUc.getTrendingShows(filter: mapFilter);
        } else {
          if (filter.$2 != null) {
            if (filter.$1.type == FilterType.year) {
              var yearStr = filter.$2!.sendValue;
              var year = int.parse(yearStr);
              final DateTime lte = yearStr == DateTime.now().year.toString()
                  ? DateTime.now()
                  : DateTime(year, 12, 31, 23, 59);
              final DateTime gte = DateTime(year);
              mapFilter["primary_release_date.lte"] = _formatter.format(lte);
              mapFilter["primary_release_date.gte"] = _formatter.format(gte);
              mapFilter["sort_by"] = "primary_release_date.desc";
            } else {
              mapFilter["with_genres"] = filter.$2!.sendValue;
            }
          }
          if (filter.$1.type == FilterType.popular) {
            mapFilter["sort_by"] = "popularity.desc";
          }
          if (filter.$1.type == FilterType.topRated) {
            mapFilter["sort_by"] = "vote_average.desc";
            mapFilter["vote_count.gte"] = "200";
          }
          res = await mediaUc.discoverShows(filter: mapFilter);
        }
      }
      _currentPage = res.page;
      if (selectedItem.value == null) {
        selectedItem.value = res.results[0];
      }
      mediaItems.value.addAll(res.results);
      mediaItems.value = List.from(mediaItems.value);
      loading.value = false;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting more media $e");
      }
      loading.value = false;
      rethrow;
    }
  }

  void dispose() {
    loading.dispose();
    selectedItem.dispose();
    mediaItems.dispose();
    cFilter.dispose();
  }
}
