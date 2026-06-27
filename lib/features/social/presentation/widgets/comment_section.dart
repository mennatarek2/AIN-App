import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/profile_photo_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/report_comment.dart';
import '../providers/social_providers.dart';
import 'comment_tile.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _countComments(List<ReportComment> comments) {
    var total = 0;
    for (final comment in comments) {
      total += 1;
      total += _countComments(comment.replies);
    }
    return total;
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(
        widget.reportId,
        text,
        null,
      );
      ref.invalidate(reportCommentsProvider(widget.reportId));
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال التعليق: $e'),
          backgroundColor: context.semantic.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(reportCommentsProvider(widget.reportId));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final photoUrl = ref.watch(profilePhotoUrlProvider);
    final count = commentsAsync.valueOrNull != null
        ? _countComments(commentsAsync.valueOrNull!)
        : 0;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'التعليقات ($count)',
            textDirection: TextDirection.rtl,
            style: context.text.titleMedium,
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppSpacing.md),
            _CommentInputField(
              controller: _controller,
              photoUrl: photoUrl,
              isSubmitting: _isSubmitting,
              onSend: _submitComment,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          commentsAsync.when(
            loading: () => const Column(
              children: [
                _CommentShimmerCard(),
                SizedBox(height: AppSpacing.sm),
                _CommentShimmerCard(),
              ],
            ),
            error: (_, __) => Text(
              'تعذر تحميل التعليقات',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: context.semantic.textMuted),
            ),
            data: (comments) {
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'لا توجد تعليقات بعد',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => CommentTile(
                  comment: comments[index],
                  reportId: widget.reportId,
                  isTopLevel: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatelessWidget {
  const _CommentInputField({
    required this.controller,
    required this.photoUrl,
    required this.isSubmitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? photoUrl;
  final bool isSubmitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: ProfilePhotoImage(
            imagePath: photoUrl,
            width: 32,
            height: 32,
            fallback: CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.person,
                size: 16,
                color: context.colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقاً...',
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: context.semantic.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        isSubmitting
            ? SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              )
            : IconButton(
                onPressed: onSend,
                icon: Icon(Icons.send_rounded, color: context.colors.primary),
              ),
      ],
    );
  }
}

class _CommentShimmerCard extends StatefulWidget {
  const _CommentShimmerCard();

  @override
  State<_CommentShimmerCard> createState() => _CommentShimmerCardState();
}

class _CommentShimmerCardState extends State<_CommentShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final base = context.semantic.shimmerBase;
        final highlight = context.semantic.shimmerHighlight;
        final color = Color.lerp(base, highlight, _controller.value) ?? base;

        return Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showReportCommentsSheet(
  BuildContext context, {
  required String reportId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetContext.semantic.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xxl,
                    ),
                    child: CommentSection(reportId: reportId),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
