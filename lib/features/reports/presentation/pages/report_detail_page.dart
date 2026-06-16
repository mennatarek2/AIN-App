import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_feed_provider.dart';
import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/report_model.dart';
import '../providers/report_data_providers.dart';
import '../providers/social_provider.dart';
import '../widgets/comment_tile.dart';
import '../widgets/report_attachment_gallery.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentSectionKey = GlobalKey();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportDetailProvider(widget.reportId));

    return async.when(
      loading: () => _buildLoading(),
      error: (error, _) => _buildError(error),
      data: (report) {
        if (report == null) return _buildNotFound();
        return _buildDetail(report);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Loading skeleton
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primarySoft),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // ---------------------------------------------------------------------------
  // Error states
  // ---------------------------------------------------------------------------

  Widget _buildError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 403) return _buildAccessDenied();
      if (error.statusCode == 404) return _buildNotFound();
    }
    return _buildNetworkError(error.toString());
  }

  Widget _buildAccessDenied() => _FullPageMessage(
    icon: Icons.lock_outline_rounded,
    title: 'غير مصرح',
    body: 'لا تملك صلاحية عرض هذا البلاغ.',
    actionLabel: 'عودة',
    onAction: () => Navigator.of(context).pop(),
  );

  Widget _buildNotFound() => _FullPageMessage(
    icon: Icons.search_off_rounded,
    title: 'البلاغ غير موجود',
    body: 'ربما تم حذف هذا البلاغ أو أن الرابط غير صحيح.',
    actionLabel: 'عودة',
    onAction: () => Navigator.of(context).pop(),
  );

  Widget _buildNetworkError(String message) => _FullPageMessage(
    icon: Icons.wifi_off_rounded,
    title: 'خطأ في الاتصال',
    body: message,
    actionLabel: 'إعادة المحاولة',
    onAction: () => ref.refresh(reportDetailProvider(widget.reportId)),
  );

  // ---------------------------------------------------------------------------
  // Full detail screen
  // ---------------------------------------------------------------------------

  Widget _buildDetail(ReportModel report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentProfile = ref.watch(profileProvider);
    final currentUserId = currentProfile?.id ?? ref.watch(currentUserProvider)?.id;
    final isOwner = currentUserId != null &&
        report.createdById != null &&
        report.createdById == currentUserId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ----- SliverAppBar -----
          SliverAppBar(
            expandedHeight: report.imagePath.isNotEmpty ? 220 : 100,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.primarySoft,
            foregroundColor: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            flexibleSpace: FlexibleSpaceBar(
              background: report.imagePath.isNotEmpty
                  ? Image.network(
                      report.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: AppColors.primarySoft,
                      ),
                    )
                  : null,
              title: Text(
                report.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              // Share
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'مشاركة',
                onPressed: () => _share(report),
              ),
              // Visibility (owner only)
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'تعديل الظهور',
                  onPressed: () => _showVisibilitySheet(report),
                ),
              // Delete (owner only)
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'حذف البلاغ',
                  color: Colors.redAccent,
                  onPressed: () => _confirmDelete(report),
                ),
            ],
          ),

          // ----- Body content -----
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Status + Visibility chips
                _StatusRow(report: report),
                const SizedBox(height: 16),
                // Metadata
                _MetadataSection(report: report),
                const SizedBox(height: 16),
                // Reporter
                _ReporterSection(
                  report: report,
                  isOwner: isOwner,
                ),
                const SizedBox(height: 16),
                // Description
                _DescriptionSection(report: report),
                const SizedBox(height: 16),
                // Attachments
                if (report.attachments.isNotEmpty) ...[
                  _SectionLabel(label: 'المرفقات'),
                  ReportAttachmentGallery(attachments: report.attachments),
                  const SizedBox(height: 16),
                ],
                // Map
                _MapSection(report: report),
                const SizedBox(height: 16),
                // Social bar
                _SocialBar(
                  reportId: report.id,
                  onCommentsTap: _scrollToComments,
                ),
                const Divider(height: 32),
                // Comments section
                _CommentsSection(
                  key: _commentSectionKey,
                  reportId: report.id,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      // Comment compose bar
      bottomNavigationBar: _CommentCompose(
        controller: _commentController,
        reportId: widget.reportId,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scroll to comments
  // ---------------------------------------------------------------------------

  void _scrollToComments() {
    final ctx = _commentSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Share
  // ---------------------------------------------------------------------------

  void _share(ReportModel report) {
    final text =
        'تفاصيل البلاغ: ${report.title}\n${report.description}\n'
        'الحالة: ${report.statusLabel}';
    Share.share(text, subject: report.title);
  }

  // ---------------------------------------------------------------------------
  // Visibility sheet
  // ---------------------------------------------------------------------------

  void _showVisibilitySheet(ReportModel report) {
    final options = [
      _VisibilityOption(label: 'عام', value: 'Public', icon: Icons.public),
      _VisibilityOption(
        label: 'سري',
        value: 'Confidential',
        icon: Icons.lock_outline,
      ),
      _VisibilityOption(
        label: 'مجهول',
        value: 'Anonymous',
        icon: Icons.person_off_outlined,
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعديل ظهور البلاغ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...options.map(
              (opt) => ListTile(
                leading: Icon(opt.icon, color: AppColors.primary),
                title: Text(opt.label, textDirection: TextDirection.rtl),
                trailing: report.visibility?.toLowerCase() ==
                        opt.value.toLowerCase()
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _updateVisibility(report.id, opt.value);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateVisibility(String id, String visibility) async {
    try {
      await ref.read(reportRepositoryProvider).updateVisibility(id, visibility);
      ref.invalidate(reportDetailProvider(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث ظهور البلاغ بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  void _confirmDelete(ReportModel report) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف البلاغ',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا البلاغ؟ هذا الإجراء لا يمكن التراجع عنه '
          'وسيؤدي إلى فقدان نقاط الثقة المكتسبة.',
          textDirection: TextDirection.rtl,
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteReport(report.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String id) async {
    try {
      await ref.read(reportRepositoryProvider).deleteReport(id);
      // Invalidate related providers
      ref.invalidate(myReportsProvider);
      ref.invalidate(publicFeedProvider);
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.myReports,
          (route) => route.settings.name == AppRoutes.home,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          _Chip(
            label: report.statusLabel,
            color: report.statusColor,
          ),
          if (report.visibility != null)
            _Chip(
              label: _visibilityLabel(report.visibility!),
              color: AppColors.primary,
              icon: _visibilityIcon(report.visibility!),
            ),
        ],
      ),
    );
  }

  String _visibilityLabel(String v) {
    switch (v.toLowerCase()) {
      case 'public': return 'عام';
      case 'anonymous': return 'مجهول';
      case 'confidential': return 'سري';
      default: return v;
    }
  }

  IconData _visibilityIcon(String v) {
    switch (v.toLowerCase()) {
      case 'anonymous': return Icons.person_off_outlined;
      case 'confidential': return Icons.lock_outline;
      default: return Icons.public;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            report.title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          if (report.categoryName != null)
            _MetaRow(
              icon: Icons.category_outlined,
              label: report.categoryName!,
              color: subColor,
            ),
          if (report.subCategoryName != null)
            _MetaRow(
              icon: Icons.label_outline,
              label: report.subCategoryName!,
              color: subColor,
            ),
          _MetaRow(
            icon: Icons.access_time_rounded,
            label: report.submittedAgo.isNotEmpty ? report.submittedAgo : 'الآن',
            color: subColor,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 13, color: color),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 15, color: color),
        ],
      ),
    );
  }
}

class _ReporterSection extends StatelessWidget {
  const _ReporterSection({required this.report, required this.isOwner});
  final ReportModel report;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final vis = report.visibility?.toLowerCase();

    // Hide section for anonymous/confidential reports unless viewer is owner
    if ((vis == 'anonymous' || vis == 'confidential') && !isOwner) {
      return const SizedBox.shrink();
    }

    final isMasked = report.createdByName == 'مجهول الهوية';
    final reporterName = report.reporter?.name ?? report.createdByName;
    final displayName = isMasked
        ? 'مجهول الهوية'
        : (reporterName?.trim().isNotEmpty == true ? reporterName!.trim() : '');
    final photoUrl = report.reporter?.resolvedPhotoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (displayName.isNotEmpty)
                Text(
                  displayName,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              const Text(
                'المُبلِّغ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: isMasked
                ? const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.primary,
                  )
                : photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: CachedAppImage(
                      imagePath: photoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.person_outline, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = report.fullDescription.isNotEmpty
        ? report.fullDescription
        : report.description;
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionLabel(label: 'الوصف'),
          const SizedBox(height: 6),
          Text(
            text,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    if (report.latitude == 0 && report.longitude == 0) {
      return const SizedBox.shrink();
    }

    final latLng = LatLng(report.latitude, report.longitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionLabel(label: 'الموقع'),
          if (report.displayLocation != null &&
              report.displayLocation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (report.mapsUrl != null && report.mapsUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(report.mapsUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('فتح في Google Maps'),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      report.displayLocation!,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: latLng,
                  zoom: 15,
                ),
                markers: {
                  Marker(markerId: const MarkerId('report'), position: latLng),
                },
                // Make map read-only
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBar extends ConsumerWidget {
  const _SocialBar({required this.reportId, required this.onCommentsTap});
  final String reportId;
  final VoidCallback onCommentsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeState = ref.watch(likeProvider(reportId));
    final commentsAsync = ref.watch(commentsProvider(reportId));
    final commentCount = commentsAsync.valueOrNull?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Comments
          InkWell(
            onTap: onCommentsTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '$commentCount',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Like
          InkWell(
            onTap: () => ref.read(likeProvider(reportId).notifier).toggle(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    likeState.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: likeState.isLiked ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${likeState.count}',
                    style: TextStyle(
                      color: likeState.isLiked ? Colors.red : Colors.grey,
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
}

class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(commentsProvider(reportId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SectionLabel(label: 'التعليقات'),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'تعذر تحميل التعليقات',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            data: (comments) {
              if (comments.isEmpty) {
                return Text(
                  'لا توجد تعليقات بعد. كن أول من يعلّق!',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.grey.shade500),
                );
              }
              return Column(
                children: comments
                    .map((c) => CommentTile(comment: c, reportId: reportId))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentCompose extends ConsumerWidget {
  const _CommentCompose({
    required this.controller,
    required this.reportId,
  });

  final TextEditingController controller;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final commentState = ref.watch(commentNotifierProvider(reportId));

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark
              : Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            commentState.isLoading
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      ref
                          .read(commentNotifierProvider(reportId).notifier)
                          .submit(text);
                      controller.clear();
                    },
                  ),
            Expanded(
              child: TextField(
                controller: controller,
                textDirection: TextDirection.rtl,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقاً...',
                  hintTextDirection: TextDirection.rtl,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A2060)
                      : const Color(0xFFF0F4FF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-page error/empty state
// ---------------------------------------------------------------------------

class _FullPageMessage extends StatelessWidget {
  const _FullPageMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primarySoft),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _VisibilityOption {
  const _VisibilityOption({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
}
