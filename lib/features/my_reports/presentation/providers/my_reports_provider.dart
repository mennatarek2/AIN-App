import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/domain/report_model.dart';
import '../../../reports/domain/repositories/report_repository.dart';
import '../../../reports/presentation/providers/report_data_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../social/presentation/providers/social_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status filter options
// ─────────────────────────────────────────────────────────────────────────────

/// Filter options for My Reports list.
enum MyReportsFilter {
  all(null, 'الكل'),
  underReview('UnderReview', 'قيد المراجعة'),
  dispatched('Dispatched', 'موزع'),
  resolved('Resolved', 'تم الحل'),
  rejected('Rejected', 'مرفوض');

  const MyReportsFilter(this.apiValue, this.label);

  final String? apiValue;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class MyReportsState {
  const MyReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.filter = MyReportsFilter.all,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  final List<ReportModel> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final MyReportsFilter filter;
  final int page;
  final bool hasMore;
  final String? error;

  MyReportsState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    MyReportsFilter? filter,
    int? page,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return MyReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class MyReportsNotifier extends StateNotifier<MyReportsState> {
  MyReportsNotifier(this._repo, this._ref) : super(const MyReportsState()) {
    refresh();
  }

  final ReportRepository _repo;
  final Ref _ref;
  static const int _pageSize = 10;

  // ── Refresh (reset to page 1) ──

  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, page: 1, clearError: true);

    try {
      final items = await _repo.fetchMyReports(
        pageNumber: 1,
        pageSize: _pageSize,
        statusFilter: state.filter.apiValue,
      );
      if (!mounted) return;
      state = state.copyWith(
        reports: items,
        isLoading: false,
        page: 1,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Load more (append next page) ──

  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final items = await _repo.fetchMyReports(
        pageNumber: nextPage,
        pageSize: _pageSize,
        statusFilter: state.filter.apiValue,
      );
      if (!mounted) return;
      state = state.copyWith(
        reports: [...state.reports, ...items],
        isLoadingMore: false,
        page: nextPage,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ── Filter ──

  Future<void> setFilter(MyReportsFilter filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter);
    await refresh();
  }

  // ── Visibility update ──

  Future<void> updateVisibility(String id, String visibility) async {
    try {
      await _repo.updateVisibility(id, visibility);
      // Update local state
      final updated = state.reports.map((r) {
        return r.id == id ? r.copyWith(visibility: visibility) : r;
      }).toList();
      if (mounted) state = state.copyWith(reports: updated);
    } catch (_) {
      // Ignore — caller can handle
    }
  }

  // ── Delete ──

  Future<bool> deleteReport(String id) async {
    // Optimistic removal
    final originalReports = [...state.reports];
    final updatedReports = state.reports.where((r) => r.id != id).toList();
    if (mounted) state = state.copyWith(reports: updatedReports);

    try {
      await _repo.deleteReport(id);

      // Refresh trust profile immediately after successful deletion
      _ref.invalidate(myTrustProvider);
      _ref.invalidate(profileProvider);

      return true;
    } catch (e) {
      // On 404, item is gone upstream — keep it removed locally
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('404') || errStr.contains('not found')) {
        _ref.invalidate(myTrustProvider);
        _ref.invalidate(profileProvider);
        return true;
      }

      // On other errors, restore the list
      if (mounted) state = state.copyWith(reports: originalReports);
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final myReportsProvider =
    StateNotifierProvider<MyReportsNotifier, MyReportsState>((ref) {
      final repo = ref.watch(reportRepositoryProvider);
      return MyReportsNotifier(repo, ref);
    });

// Legacy alias (used by some existing code)
typedef MyReport = ReportModel;
