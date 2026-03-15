import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/listing.dart';
import '../services/api_client.dart';
import 'listings_provider.dart';

part 'browse_accumulator_provider.g.dart';

/// State for the accumulating browse pagination.
@immutable
class BrowseAccumulatorState {
  const BrowseAccumulatorState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  final List<Listing> items;
  final int totalCount;
  final bool isLoadingMore;
  final bool loadMoreError;

  bool get hasMore => items.length < totalCount;

  BrowseAccumulatorState copyWith({
    List<Listing>? items,
    int? totalCount,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) =>
      BrowseAccumulatorState(
        items: items ?? this.items,
        totalCount: totalCount ?? this.totalCount,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError ?? this.loadMoreError,
      );
}

@riverpod
class BrowseAccumulator extends _$BrowseAccumulator {
  int _currentPage = 1;
  CancelToken? _cancelToken;

  @override
  Future<BrowseAccumulatorState> build() async {
    ref.watch(browseFiltersProvider);

    // Cancel any in-flight request when filters change.
    _cancelToken?.cancel('filters changed');
    _cancelToken = CancelToken();
    _currentPage = 1;

    final result = await _fetchPage(1);
    return BrowseAccumulatorState(
      items: result.items,
      totalCount: result.count,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );

    _cancelToken?.cancel('new loadMore');
    _cancelToken = CancelToken();
    final nextPage = _currentPage + 1;

    try {
      final result = await _fetchPage(nextPage);
      _currentPage = nextPage;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          totalCount: result.count,
          isLoadingMore: false,
          loadMoreError: false,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: true),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: true),
      );
    }
  }

  Future<PaginatedListings> _fetchPage(int page) async {
    final filters = ref.read(browseFiltersProvider);
    final dio = ref.read(apiClientProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/api/listings/',
      queryParameters: buildBrowseQuery(filters, page: page),
      cancelToken: _cancelToken,
    );
    return PaginatedListings.fromJson(response.data!);
  }
}
