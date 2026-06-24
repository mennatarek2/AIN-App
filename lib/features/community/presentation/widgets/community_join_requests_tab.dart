import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../models/join_request.dart';
import '../providers/communities_provider.dart';
import 'community_dialogs.dart';

/// Complete Join Requests tab: loading, error, empty, list, approve/reject.
/// Supports pull-to-refresh independently via its own RefreshIndicator + ListView.
class CommunityJoinRequestsTab extends ConsumerStatefulWidget {
  const CommunityJoinRequestsTab({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  ConsumerState<CommunityJoinRequestsTab> createState() =>
      _CommunityJoinRequestsTabState();
}

class _CommunityJoinRequestsTabState
    extends ConsumerState<CommunityJoinRequestsTab> {
  String? _processingUserId;

  String _formatRequestDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _refresh() async {
    ref.invalidate(pendingJoinRequestsProvider(widget.communityId));
    await ref.read(pendingJoinRequestsProvider(widget.communityId).future);
  }

  Future<void> _approve(String userId) async {
    setState(() => _processingUserId = userId);
    final error = await ref
        .read(communitiesProvider.notifier)
        .approveJoinRequest(widget.communityId, userId);
    if (mounted) setState(() => _processingUserId = null);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم قبول طلب الانضمام', textDirection: TextDirection.rtl),
      ),
    );
  }

  Future<void> _reject(String userId, String userName) async {
    if (!await CommunityDialogs.confirmRejectJoinRequest(
      context,
      userName: userName,
    )) {
      return;
    }

    setState(() => _processingUserId = userId);
    final error = await ref
        .read(communitiesProvider.notifier)
        .rejectJoinRequest(widget.communityId, userId);
    if (mounted) setState(() => _processingUserId = null);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفض طلب الانضمام', textDirection: TextDirection.rtl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(
      pendingJoinRequestsProvider(widget.communityId),
    );

    return requestsAsync.when(
      loading: _buildLoading,
      error: (error, _) => _buildError(context, error),
      data: (requests) {
        final pending = requests
            .where((r) => r.status == JoinStatus.pending)
            .toList();
        return _buildList(context, pending);
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text(
              'جارٍ تحميل الطلبات…',
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          AppSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: context.semantic.error,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'تعذّر تحميل طلبات الانضمام',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'اسحب للأسفل لإعادة المحاولة',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<JoinRequestDto> pending) {
    if (pending.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            AppSurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: context.semantic.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'لا توجد طلبات انضمام معلقة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: context.text.titleSmall?.copyWith(
                        color: context.semantic.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ستظهر هنا طلبات الانضمام الجديدة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: pending.length,
        separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final request = pending[index];
          final isProcessing = _processingUserId == request.userId;
          return _JoinRequestCard(
            request: request,
            isProcessing: isProcessing,
            onApprove: () => _approve(request.userId),
            onReject: () => _reject(request.userId, request.userName),
            formatDate: _formatRequestDate,
          );
        },
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
    required this.formatDate,
  });

  final JoinRequestDto request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Row: avatar + name + date ─────────────────────────────
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _JoinRequestAvatar(request: request),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      textDirection: TextDirection.rtl,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: context.semantic.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'طُلب في ${formatDate(request.requestedAt)}',
                          textDirection: TextDirection.rtl,
                          style: context.text.labelSmall?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'معلّق',
                  style: context.text.labelSmall?.copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // ── Action Row: Reject | Approve ──────────────────────────────────
          if (isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            Row(
              textDirection: TextDirection.rtl,
              children: [
                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.semantic.error,
                      side: BorderSide(
                        color: context.semantic.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.semantic.error,
                    ),
                    label: Text(
                      'رفض',
                      style: TextStyle(color: context.semantic.error),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Approve button
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: context.primaryGradient,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: context.semantic.textOnPrimary,
                      ),
                      label: Text(
                        'قبول',
                        style: TextStyle(
                          color: context.semantic.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _JoinRequestAvatar extends StatelessWidget {
  const _JoinRequestAvatar({required this.request});

  final JoinRequestDto request;

  @override
  Widget build(BuildContext context) {
    final photoUrl = request.profilePhotoUrl?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedAppImage(
          imagePath: photoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: _AvatarFallback(userName: request.userName),
        ),
      );
    }
    return _AvatarFallback(userName: request.userName);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
      child: Text(
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          color: context.colors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}
