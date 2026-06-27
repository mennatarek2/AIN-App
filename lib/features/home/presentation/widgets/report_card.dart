import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../social/presentation/widgets/comment_section.dart';

class ReportCard extends ConsumerStatefulWidget {
  const ReportCard({
    super.key,
    required this.reportId,
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
    this.statusColor,
    this.statusLabel,
    this.onTap,
  });

  final String reportId;
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
  final Color? statusColor;
  final String? statusLabel;
  final VoidCallback? onTap;

  @override
  ConsumerState<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<ReportCard> {
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

  Color get _accentColor =>
      widget.statusColor ??
      widget.tags.lastOrNull?.dotColor ??
      context.colors.primary;

  Future<void> _openInMaps() async {
    final url = widget.locationMapUrl?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLike() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل دخولك للإعجاب بالبلاغ'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    await ref
        .read(reportLikeNotifierProvider(widget.reportId).notifier)
        .toggle();
  }

  void _handleComment() {
    showReportCommentsSheet(context, reportId: widget.reportId);
  }

  void _handleShare() {
    final status = widget.statusLabel?.trim();
    final buffer = StringBuffer('تفاصيل البلاغ: ${widget.title}');
    if (widget.description.trim().isNotEmpty) {
      buffer.write('\n${widget.description.trim()}');
    }
    if (status != null && status.isNotEmpty) {
      buffer.write('\nالحالة: $status');
    }
    Share.share(buffer.toString(), subject: widget.title);
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final images = _displayImages;
    final hasReporterPhoto =
        widget.reporterAvatarUrl != null &&
        widget.reporterAvatarUrl!.trim().isNotEmpty;
    final statusTag = widget.tags.lastOrNull;
    final likeAsync = ref.watch(reportLikeNotifierProvider(widget.reportId));
    final likeCount = likeAsync.valueOrNull?.totalLikes ?? 0;
    final isLiked = likeAsync.valueOrNull?.isLikedByCaller ?? false;
    final isLikeLoading = likeAsync.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: semantic.borderSubtle),
            boxShadow: context.cardShadows,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: BorderDirectional(
                start: BorderSide(color: _accentColor, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    _accentColor.withValues(alpha: 0.12),
                                child: hasReporterPhoto
                                    ? ClipOval(
                                        child: CachedAppImage(
                                          imagePath: widget.reporterAvatarUrl!,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorWidget: Icon(
                                            Icons.person_rounded,
                                            size: 18,
                                            color: _accentColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: _accentColor,
                                      ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.username.isEmpty
                                          ? 'مواطن'
                                          : widget.username,
                                      textDirection: TextDirection.rtl,
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.timeAgo,
                                      style: context.text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (statusTag != null)
                                _StatusBadge(
                                  label: statusTag.label,
                                  color: statusTag.dotColor,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            widget.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.description.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xxs,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: Text(
                              widget.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: context.text.bodySmall?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        if (images.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: images.length == 1
                                    ? CachedAppImage(
                                        imagePath: images.first,
                                        fit: BoxFit.cover,
                                        errorWidget: _imageError(context),
                                      )
                                    : Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          PageView.builder(
                                            controller: _pageController,
                                            itemCount: images.length,
                                            onPageChanged: (index) {
                                              setState(
                                                () => _currentImageIndex = index,
                                              );
                                            },
                                            itemBuilder: (context, index) {
                                              return CachedAppImage(
                                                imagePath: images[index],
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    _imageError(context),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            bottom: AppSpacing.xs,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                images.length,
                                                (index) => AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  width:
                                                      index == _currentImageIndex
                                                      ? 16
                                                      : 6,
                                                  height: 6,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                    color:
                                                        index ==
                                                            _currentImageIndex
                                                        ? semantic.textOnPrimary
                                                        : semantic.textOnPrimary
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
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
                        if (widget.tags.length > 1) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xxs,
                              textDirection: TextDirection.rtl,
                              children: widget.tags
                                  .take(widget.tags.length - 1)
                                  .map((tag) => _TagChip(tag: tag))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (widget.locationPreview != null &&
                            widget.locationPreview!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: semantic.chipBackground,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      widget.locationPreview!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      style: context.text.bodySmall,
                                    ),
                                  ),
                                  if (widget.locationMapUrl != null &&
                                      widget.locationMapUrl!.trim().isNotEmpty)
                                    IconButton(
                                      onPressed: _openInMaps,
                                      icon: Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: context.colors.primary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (widget.attachmentCount > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              0,
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 14,
                                  color: semantic.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  '${widget.attachmentCount} مرفق',
                                  style: context.text.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: semantic.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _ActionButton(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: likeCount > 0 ? '$likeCount' : 'إعجاب',
                        iconColor: isLiked
                            ? context.semantic.error
                            : context.semantic.textMuted,
                        isLoading: isLikeLoading,
                        onTap: _handleLike,
                      ),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: widget.commentCount > 0
                            ? '${widget.commentCount}'
                            : 'تعليق',
                        onTap: _handleComment,
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'مشاركة',
                        onTap: _handleShare,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageError(BuildContext context) {
    return Container(
      color: context.semantic.chipBackground,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.semantic.textMuted,
          size: 36,
        ),
      ),
    );
  }
}

class ReportTag {
  ReportTag({
    required this.label,
    required this.dotColor,
    this.showPin = false,
    this.showDot = true,
  });

  final String label;
  final Color dotColor;
  final bool showPin;
  final bool showDot;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final ReportTag tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.semantic.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          if (tag.showDot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: tag.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            tag.label,
            style: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.primary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? context.semantic.textMuted,
                ),
              const SizedBox(height: 2),
              Text(label, style: context.text.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
