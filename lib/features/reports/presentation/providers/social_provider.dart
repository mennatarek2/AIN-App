import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/social_remote_data_source.dart';
import '../../domain/comment_model.dart';
import 'report_data_providers.dart';

// =============================================================================
// Comments
// =============================================================================

/// Fetches all comments for a given report. Keyed by report ID.
final commentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, reportId) async {
      final ds = ref.read(socialRemoteDataSourceProvider);
      return ds.fetchComments(reportId);
    });

// Comment submission state
class CommentState {
  const CommentState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
  CommentState copyWith({bool? isLoading, String? error}) =>
      CommentState(isLoading: isLoading ?? this.isLoading, error: error);
}

class CommentNotifier extends StateNotifier<CommentState> {
  CommentNotifier(this._ds, this._ref, this._reportId)
      : super(const CommentState());

  final SocialRemoteDataSource _ds;
  final Ref _ref;
  final String _reportId;

  Future<void> submit(String content, {String? parentId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ds.postComment(_reportId, content, parentCommentId: parentId);
      // Refresh comment list
      _ref.invalidate(commentsProvider(_reportId));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final commentNotifierProvider = StateNotifierProvider.family<
    CommentNotifier, CommentState, String>((ref, reportId) {
  final ds = ref.read(socialRemoteDataSourceProvider);
  return CommentNotifier(ds, ref, reportId);
});

// =============================================================================
// Likes
// =============================================================================

class LikeState {
  const LikeState({this.count = 0, this.isLiked = false, this.isLoading = false});
  final int count;
  final bool isLiked;
  final bool isLoading;
  LikeState copyWith({int? count, bool? isLiked, bool? isLoading}) => LikeState(
    count: count ?? this.count,
    isLiked: isLiked ?? this.isLiked,
    isLoading: isLoading ?? this.isLoading,
  );
}

class LikeNotifier extends StateNotifier<LikeState> {
  LikeNotifier(this._ds, this._reportId, {int initialCount = 0})
      : super(LikeState(count: initialCount));

  final SocialRemoteDataSource _ds;
  final String _reportId;

  Future<void> toggle() async {
    if (state.isLoading) return;
    // Optimistic update
    final wasLiked = state.isLiked;
    state = state.copyWith(
      isLiked: !wasLiked,
      count: wasLiked ? state.count - 1 : state.count + 1,
      isLoading: true,
    );
    try {
      final serverCount = await _ds.toggleLike(_reportId);
      state = state.copyWith(
        count: serverCount >= 0 ? serverCount : state.count,
        isLoading: false,
      );
    } catch (_) {
      // Revert optimistic update on failure
      state = state.copyWith(isLiked: wasLiked, count: wasLiked ? state.count + 1 : state.count - 1, isLoading: false);
    }
  }
}

final likeProvider = StateNotifierProvider.family<LikeNotifier, LikeState, String>((ref, reportId) {
  final ds = ref.read(socialRemoteDataSourceProvider);
  return LikeNotifier(ds, reportId);
});
