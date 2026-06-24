import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class CommentItemData {
  final String id;
  final String username;
  final String text;
  final String timeAgo;
  final int likesCount;
  final bool isLiked;

  const CommentItemData({
    required this.id,
    required this.username,
    required this.text,
    required this.timeAgo,
    this.likesCount = 0,
    this.isLiked = false,
  });

  CommentItemData copyWith({
    String? id,
    String? username,
    String? text,
    String? timeAgo,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommentItemData(
      id: id ?? this.id,
      username: username ?? this.username,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class CommentsBottomSheet extends StatefulWidget {
  final List<CommentItemData> comments;
  final ValueChanged<String> onLikeComment;
  final ValueChanged<String> onSendComment;

  const CommentsBottomSheet({
    super.key,
    required this.comments,
    required this.onLikeComment,
    required this.onSendComment,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late List<CommentItemData> _comments;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comments = List<CommentItemData>.from(widget.comments);
  }

  @override
  void didUpdateWidget(covariant CommentsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comments != widget.comments) {
      _comments = List<CommentItemData>.from(widget.comments);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    widget.onSendComment(text);
    setState(() {
      _comments.insert(
        0,
        CommentItemData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: 'أنت',
          text: text,
          timeAgo: 'الآن',
        ),
      );
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    final semantic = context.semantic;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: semantic.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm - 2),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: semantic.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التعليقات (${_comments.length})',
                            textDirection: TextDirection.rtl,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: semantic.divider),
              Expanded(
                child: _comments.isEmpty
                    ? const _EmptyCommentsState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm + 2,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        itemCount: _comments.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: AppSpacing.sm + 2),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _CommentListItem(
                            item: comment,
                            onLike: () {
                              widget.onLikeComment(comment.id);
                              setState(() {
                                _comments[index] = comment.copyWith(
                                  isLiked: !comment.isLiked,
                                  likesCount: comment.isLiked
                                      ? comment.likesCount - 1
                                      : comment.likesCount + 1,
                                );
                              });
                            },
                          );
                        },
                      ),
              ),
              Divider(height: 1, color: semantic.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm - 2,
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textDirection: TextDirection.rtl,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'اكتب تعليقك...',
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: TextStyle(color: semantic.textMuted),
                          filled: true,
                          fillColor: semantic.surfaceInput,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm - 2),
                    GestureDetector(
                      onTap: _sendComment,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: context.semantic.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentListItem extends StatelessWidget {
  final CommentItemData item;
  final VoidCallback onLike;

  const _CommentListItem({
    required this.item,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final primaryText = context.colors.onSurface;
    final secondaryText = semantic.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: semantic.infoContainer.withValues(
              alpha: context.isDarkMode ? 0.5 : 1,
            ),
          ),
          child: Icon(Icons.person, color: context.colors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm - 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      item.username,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                  ),
                  Text(
                    item.timeAgo,
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  item.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            item.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 15,
                            color: item.isLiked
                                ? semantic.sos
                                : secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${item.likesCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        'رد',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Image(
            image: AssetImage('assets/images/comments_icon.png'),
            width: 200,
            height: 200,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'لا توجد تعليقات بعد',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.semantic.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
