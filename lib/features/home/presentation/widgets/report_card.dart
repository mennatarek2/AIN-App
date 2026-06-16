import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_app_image.dart';

class ReportCard extends StatefulWidget {
  final String username;
  final String? reporterAvatarUrl;
  final String timeAgo;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final List<ReportTag> tags;
  final int commentCount;
  final int attachmentCount;
  final String? locationPreview;
  final String? locationMapUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const ReportCard({
    super.key,
    required this.username,
    this.reporterAvatarUrl,
    required this.timeAgo,
    required this.title,
    this.description = '',
    required this.imageUrl,
    this.imageUrls = const [],
    required this.tags,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.locationPreview,
    this.locationMapUrl,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _displayImages {
    if (widget.imageUrls.isNotEmpty) return widget.imageUrls;
    if (widget.imageUrl.trim().isNotEmpty) return [widget.imageUrl];
    return const [];
  }

  Future<void> _openInMaps() async {
    final url = widget.locationMapUrl?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0D1530) : Colors.white;
    final primaryText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final dividerColor = isDark
        ? const Color(0xFF32417B)
        : const Color(0xFFE5E7EB);
    final images = _displayImages;
    final hasReporterPhoto =
        widget.reporterAvatarUrl != null &&
        widget.reporterAvatarUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16204A)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasReporterPhoto
                            ? CachedAppImage(
                                imagePath: widget.reporterAvatarUrl!,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 16,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.username,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? primaryText : AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.access_time, size: 13, color: secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      widget.timeAgo,
                      style: TextStyle(fontSize: 13, color: secondaryText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryText,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8),
          // Description (if provided)
          if (widget.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                  height: 1.5,
                ),
              ),
            ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: images.length == 1
                      ? CachedAppImage(
                          imagePath: images.first,
                          fit: BoxFit.cover,
                          errorWidget: _imageError(isDark),
                        )
                      : Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return CachedAppImage(
                                  imagePath: images[index],
                                  fit: BoxFit.cover,
                                  errorWidget: _imageError(isDark),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  images.length,
                                  (index) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == _currentImageIndex
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.tags
                  .map(
                    (tag) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: _TagChip(tag: tag),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (widget.locationPreview != null &&
              widget.locationPreview!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      widget.locationPreview!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ),
                  if (widget.locationMapUrl != null &&
                      widget.locationMapUrl!.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('فتح في الخرائط'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Attachment count chip
          if (widget.attachmentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: 13,
                    color: secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.attachmentCount} مرفق',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.favorite_border,
                    label: 'إعجاب',
                    onTap: widget.onLike,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: widget.commentCount > 0
                        ? 'تعليق (${widget.commentCount})'
                        : 'تعليق',
                    onTap: widget.onComment,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'مشاركة',
                    onTap: widget.onShare,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  }

  Widget _imageError(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A255C) : Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: isDark ? AppColors.textSecondaryDark : Colors.grey,
          size: 36,
        ),
      ),
    );
  }
}

class ReportTag {
  final String label;
  final Color dotColor;
  final bool showPin;
  final bool showDot;

  ReportTag({
    required this.label,
    required this.dotColor,
    this.showPin = false,
    this.showDot = true,
  });
}

class _TagChip extends StatelessWidget {
  final ReportTag tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tagTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primarySoft.withValues(alpha: 0.2)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primarySoft.withValues(alpha: 0.35)
              : const Color(0xFFD6E9FF),
          width: 0.8,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          tag.showPin
              ? Icon(Icons.location_on, size: 12, color: tag.dotColor)
              : tag.showDot
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tag.dotColor,
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox(width: 8, height: 8),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tag.label,
              style: TextStyle(
                fontSize: 11,
                color: tagTextColor,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
