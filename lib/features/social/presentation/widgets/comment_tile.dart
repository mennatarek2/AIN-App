import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/profile_photo_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/report_comment.dart';
import '../providers/social_providers.dart';

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.reportId,
    this.isTopLevel = true,
  });

  final ReportComment comment;
  final String reportId;
  final bool isTopLevel;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _showReplyField = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String? get _currentUserId {
    final profile = ref.read(profileProvider);
    return profile?.id ?? ref.read(currentUserProvider)?.id;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت متأكد من حذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.semantic.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(socialRepositoryProvider).deleteComment(widget.comment.id);
      ref.invalidate(reportCommentsProvider(widget.reportId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حذف التعليق: $e'),
          backgroundColor: context.semantic.error,
        ),
      );
    }
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(socialRepositoryProvider).addComment(
        widget.reportId,
        text,
        widget.comment.id,
      );
      ref.invalidate(reportCommentsProvider(widget.reportId));
      _replyController.clear();
      if (mounted) setState(() => _showReplyField = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الرد: $e'),
          backgroundColor: context.semantic.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isOwn =
        _currentUserId != null && comment.authorId == _currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            _CommentAvatar(photoUrl: comment.authorPhoto, size: 36),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          textDirection: TextDirection.rtl,
                          style: context.text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimeAgo(comment.createdAt),
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  if (comment.isDeleted)
                    Text(
                      '[تم حذف هذا التعليق]',
                      textDirection: TextDirection.rtl,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      comment.content,
                      textDirection: TextDirection.rtl,
                      style: context.text.bodyMedium,
                    ),
                  if (!comment.isDeleted) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _CommentLikeButton(
                          commentId: comment.id,
                          initialLikes: comment.totalLikes,
                          initialLiked: comment.isLikedByCaller,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showReplyField = !_showReplyField;
                              if (_showReplyField &&
                                  _replyController.text.isEmpty) {
                                _replyController.text =
                                    '@${comment.authorName} ';
                              }
                            });
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('رد'),
                        ),
                        if (isOwn)
                          TextButton(
                            onPressed: _confirmDelete,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              foregroundColor: context.semantic.error,
                            ),
                            child: const Text('حذف'),
                          ),
                      ],
                    ),
                  ],
                  if (_showReplyField) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            autofocus: true,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'اكتب ردًّا...',
                              hintTextDirection: TextDirection.rtl,
                              filled: true,
                              fillColor: context.semantic.surfaceInput,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 20),
                          color: context.colors.primary,
                          onPressed: _submitReply,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (widget.isTopLevel && comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 48),
            child: Column(
              children: comment.replies
                  .map(
                    (reply) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: CommentTile(
                        comment: reply,
                        reportId: widget.reportId,
                        isTopLevel: false,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return 'منذ فترة';
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ProfilePhotoImage(
        imagePath: photoUrl,
        width: size,
        height: size,
        fallback: CircleAvatar(
          radius: size / 2,
          backgroundColor: context.colors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.person, size: size * 0.5, color: context.colors.primary),
        ),
      ),
    );
  }
}

class _CommentLikeButton extends ConsumerWidget {
  const _CommentLikeButton({
    required this.commentId,
    required this.initialLikes,
    required this.initialLiked,
  });

  final String commentId;
  final int initialLikes;
  final bool initialLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final likeAsync = ref.watch(commentLikeNotifierProvider(commentId));
    final likes = likeAsync.valueOrNull?.totalLikes ?? initialLikes;
    final isLiked = likeAsync.valueOrNull?.isLikedByCaller ?? initialLiked;

    return InkWell(
      onTap: isAuthenticated
          ? () => ref
                .read(commentLikeNotifierProvider(commentId).notifier)
                .toggle(initialLikes, initialLiked)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('سجّل دخولك للإعجاب بالتعليق'),
                  backgroundColor: context.semantic.error,
                ),
              );
            },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: isLiked
                  ? context.semantic.error
                  : context.semantic.textMuted,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$likes',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
