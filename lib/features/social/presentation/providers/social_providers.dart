import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/like_result.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/user_trust.dart';
import '../../domain/repositories/i_social_repository.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return SocialRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

final socialRepositoryProvider = Provider<ISocialRepository>((ref) {
  return SocialRepositoryImpl(
    remoteDataSource: ref.watch(socialRemoteDataSourceProvider),
  );
});

// ─── Comments ────────────────────────────────────────────────────────────────

final reportCommentsProvider =
    FutureProvider.autoDispose.family<List<ReportComment>, String>((
      ref,
      reportId,
    ) async {
      return ref.read(socialRepositoryProvider).getComments(reportId);
    });

// ─── Report likes (optimistic) ───────────────────────────────────────────────

final reportLikeNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ReportLikeNotifier, LikeResult, String>(ReportLikeNotifier.new);

class ReportLikeNotifier
    extends AutoDisposeFamilyAsyncNotifier<LikeResult, String> {
  @override
  Future<LikeResult> build(String reportId) async {
    return ref.read(socialRepositoryProvider).getReportLikes(reportId);
  }

  Future<bool> toggle() async {
    final previous = state.valueOrNull;
    final optimistic = previous ??
        const LikeResult(totalLikes: 0, isLikedByCaller: false);

    state = AsyncData(
      optimistic.copyWith(
        isLikedByCaller: !optimistic.isLikedByCaller,
        totalLikes: optimistic.isLikedByCaller
            ? optimistic.totalLikes - 1
            : optimistic.totalLikes + 1,
      ),
    );

    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .toggleReportLike(arg);
      state = AsyncData(result);
      return true;
    } catch (e) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = const AsyncData(
          LikeResult(totalLikes: 0, isLikedByCaller: false),
        );
      }
      rethrow;
    }
  }
}

// ─── Comment likes (optimistic) ──────────────────────────────────────────────

final commentLikeNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<CommentLikeNotifier, CommentLikeResult, String>(
      CommentLikeNotifier.new,
    );

class CommentLikeNotifier
    extends AutoDisposeFamilyAsyncNotifier<CommentLikeResult, String> {
  @override
  Future<CommentLikeResult> build(String commentId) async {
    return const CommentLikeResult(totalLikes: 0, isLikedByCaller: false);
  }

  Future<bool> toggle(int initialLikes, bool initialLiked) async {
    final current = state.valueOrNull ??
        CommentLikeResult(
          totalLikes: initialLikes,
          isLikedByCaller: initialLiked,
        );

    state = AsyncData(
      current.copyWith(
        isLikedByCaller: !current.isLikedByCaller,
        totalLikes: current.isLikedByCaller
            ? current.totalLikes - 1
            : current.totalLikes + 1,
      ),
    );

    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .toggleCommentLike(arg);
      state = AsyncData(result);
      return true;
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

// ─── Trust ───────────────────────────────────────────────────────────────────

final myTrustProvider = FutureProvider.autoDispose<UserTrust>((ref) async {
  final token = await ref
      .read(socialRemoteDataSourceProvider)
      .readToken();
  if (token == null || token.isEmpty) {
    return _fallbackTrust(ref);
  }

  try {
    return await ref.read(socialRepositoryProvider).getMyTrust();
  } catch (e) {
    return _fallbackTrust(ref);
  }
});

final userTrustProvider = FutureProvider.autoDispose.family<UserTrust, String>((
  ref,
  userId,
) async {
  if (userId == 'me') {
    return ref.watch(myTrustProvider.future);
  }
  return ref.read(socialRepositoryProvider).getUserTrust(userId);
});

UserTrust _fallbackTrust(Ref ref) {
  final profile = ref.read(profileProvider);
  final points = profile?.points ?? 0;
  return UserTrust(
    userId: profile?.id ?? '',
    score: points,
    tierName: _tierNameFromPoints(points),
    tierNameAr: _tierNameArFromPoints(points),
    totalReports: 0,
    resolvedReports: 0,
    totalLikesReceived: 0,
  );
}

String _tierNameFromPoints(int points) {
  if (points >= 100) return 'Guardian';
  if (points >= 50) return 'Trusted';
  if (points >= 20) return 'Contributor';
  return 'Newcomer';
}

String _tierNameArFromPoints(int points) {
  if (points >= 100) return 'حارس';
  if (points >= 50) return 'موثوق';
  if (points >= 20) return 'مساهم';
  return 'مبتدئ';
}
