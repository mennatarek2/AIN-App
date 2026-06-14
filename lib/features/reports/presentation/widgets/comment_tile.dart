import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/comment_model.dart';
import '../providers/social_provider.dart';

/// Renders a single top-level comment with an inline reply list.
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.reportId,
    this.depth = 0,
  });

  final CommentModel comment;
  final String reportId;

  /// Nesting depth (0 = top-level, 1 = reply). We cap at depth 1.
  final int depth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF3F6F9) : const Color(0xFF060C3A);
    final subColor =
        isDark ? const Color(0xFFCBD5F5) : const Color(0xFF4B5563);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: depth * 20.0,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: depth == 0 ? 20 : 16,
            backgroundColor: const Color(0xFF0099FF).withValues(alpha: 0.15),
            backgroundImage: comment.authorPhotoUrl != null
                ? NetworkImage(comment.authorPhotoUrl!)
                : null,
            child: comment.authorPhotoUrl == null
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '؟',
                    style: const TextStyle(
                      color: Color(0xFF0099FF),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + time
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Content bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2060)
                        : const Color(0xFFF0F4FF),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    comment.content,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                ),
                // Reply button (only on top-level)
                if (depth == 0)
                  _ReplyButton(reportId: reportId, parentId: comment.id),
                // Nested replies
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies.map(
                    (reply) => CommentTile(
                      comment: reply,
                      reportId: reportId,
                      depth: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return 'منذ فترة';
  }
}

class _ReplyButton extends ConsumerStatefulWidget {
  const _ReplyButton({required this.reportId, required this.parentId});
  final String reportId;
  final String parentId;

  @override
  ConsumerState<_ReplyButton> createState() => _ReplyButtonState();
}

class _ReplyButtonState extends ConsumerState<_ReplyButton> {
  bool _showInput = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showInput) {
      return TextButton(
        onPressed: () => setState(() => _showInput = true),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text(
          'رد',
          style: TextStyle(fontSize: 12, color: Color(0xFF0099FF)),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'اكتب ردًّا...',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, size: 20),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            ref
                .read(commentNotifierProvider(widget.reportId).notifier)
                .submit(text, parentId: widget.parentId);
            _controller.clear();
            setState(() => _showInput = false);
          },
        ),
      ],
    );
  }
}
