import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF0D1530) : Colors.white;
    final primaryText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final dividerColor = isDark
        ? const Color(0xFF32417B)
        : const Color(0xFFE5E7EB);
    final inputFill = isDark
        ? const Color(0xFF16204A)
        : const Color(0xFFF3F6F9);
    final hintColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475585)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: dividerColor),
              Expanded(
                child: _comments.isEmpty
                    ? _EmptyCommentsState(isDark: isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _CommentListItem(
                            item: comment,
                            isDark: isDark,
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
              Divider(height: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
                          hintStyle: TextStyle(color: hintColor),
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendComment,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
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
  final bool isDark;
  final VoidCallback onLike;

  const _CommentListItem({
    required this.item,
    required this.isDark,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF16204A) : const Color(0xFFEFF6FF),
          ),
          child: const Icon(Icons.person, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
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
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(8),
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
                                ? const Color(0xFFEF4444)
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
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
  final bool isDark;

  const _EmptyCommentsState({required this.isDark});

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
          const SizedBox(height: 8),
          Text(
            'لا توجد تعليقات بعد',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 2),
          // Text(
          //   'كن أول من يضيف تعليقًا على هذا البلاغ',
          //   style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          // ),
        ],
      ),
    );
  }
}
