import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/domain/repositories/report_repository.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/presentation/providers/report_data_providers.dart';

// ---------------------------------------------------------------------------
// Feed filter model
// ---------------------------------------------------------------------------
class FeedFilter {
  const FeedFilter({
    this.categoryId,
    this.status,
    this.search,
  });

  final String? categoryId;
  final String? status;
  final String? search;

  FeedFilter copyWith({
    Object? categoryId = _sentinel,
    Object? status = _sentinel,
    Object? search = _sentinel,
  }) {
    return FeedFilter(
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as String?,
      status: status == _sentinel ? this.status : status as String?,
      search: search == _sentinel ? this.search : search as String?,
    );
  }

  static const _sentinel = Object();
}

// ---------------------------------------------------------------------------
// Feed state
// ---------------------------------------------------------------------------
class PublicFeedState {
  const PublicFeedState({
    this.reports = const [],
    this.page = 1,
    this.pageSize = 10,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.filter = const FeedFilter(),
    this.error,
  });

  final List<ReportModel> reports;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final FeedFilter filter;
  final String? error;

  PublicFeedState copyWith({
    List<ReportModel>? reports,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    FeedFilter? filter,
    Object? error = _sentinel,
  }) {
    return PublicFeedState(
      reports: reports ?? this.reports,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      filter: filter ?? this.filter,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class PublicFeedNotifier extends StateNotifier<AsyncValue<PublicFeedState>> {
  PublicFeedNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  final ReportRepository _repository;

  // ---- Initial load -------------------------------------------------------

  Future<void> _loadInitial() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      const filter = FeedFilter();
      final results = await _repository.fetchPublicReports(
        pageNumber: 1,
        pageSize: 10,
      );
      if (!mounted) return;
      state = AsyncValue.data(
        PublicFeedState(
          reports: results,
          page: 1,
          hasMore: results.length >= 10,
          filter: filter,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  // ---- Pull-to-refresh ----------------------------------------------------

  Future<void> refresh() async {
    if (!mounted) return;
    final currentFilter = state.valueOrNull?.filter ?? const FeedFilter();

    // Mark refreshing but keep current data visible
    state = state.whenData(
      (s) => s.copyWith(isRefreshing: true, error: null),
    );

    try {
      final results = await _repository.fetchPublicReports(
        pageNumber: 1,
        pageSize: 10,
        categoryId: currentFilter.categoryId,
        status: currentFilter.status,
        search: currentFilter.search,
      );
      if (!mounted) return;
      state = AsyncValue.data(
        PublicFeedState(
          reports: results,
          page: 1,
          hasMore: results.length >= 10,
          filter: currentFilter,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // On refresh error keep old data and surface error
      state = state.whenData(
        (s) => s.copyWith(isRefreshing: false, error: e.toString()),
      );
    }
  }

  // ---- Infinite scroll / load more ----------------------------------------

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;
      final results = await _repository.fetchPublicReports(
        pageNumber: nextPage,
        pageSize: current.pageSize,
        categoryId: current.filter.categoryId,
        status: current.filter.status,
        search: current.filter.search,
      );
      if (!mounted) return;
      state = AsyncValue.data(
        current.copyWith(
          reports: [...current.reports, ...results],
          page: nextPage,
          hasMore: results.length >= current.pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false),
      );
    }
  }

  // ---- Filters ------------------------------------------------------------

  Future<void> applyFilter(FeedFilter filter) async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final results = await _repository.fetchPublicReports(
        pageNumber: 1,
        pageSize: 10,
        categoryId: filter.categoryId,
        status: filter.status,
        search: filter.search,
      );
      if (!mounted) return;
      state = AsyncValue.data(
        PublicFeedState(
          reports: results,
          page: 1,
          hasMore: results.length >= 10,
          filter: filter,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setSearch(String query) async {
    final current = state.valueOrNull;
    final currentFilter = current?.filter ?? const FeedFilter();
    final trimmed = query.trim();

    // Avoid redundant calls
    if (currentFilter.search == (trimmed.isEmpty ? null : trimmed)) return;

    await applyFilter(
      currentFilter.copyWith(search: trimmed.isEmpty ? null : trimmed),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final publicFeedProvider =
    StateNotifierProvider<PublicFeedNotifier, AsyncValue<PublicFeedState>>(
  (ref) {
    final repository = ref.watch(reportRepositoryProvider);
    return PublicFeedNotifier(repository);
  },
);
