import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_feed_provider.dart';
import '../../../my_reports/presentation/providers/my_reports_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/report_model.dart';
import '../providers/report_data_providers.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/like_button.dart';
import '../widgets/report_attachment_gallery.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final _scrollController = ScrollController();
  final _commentSectionKey = GlobalKey();

  @override
  void dispose() {
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
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.semantic.surfaceHeader,
        foregroundColor: context.colors.onSurface,
      ),
      body: const AppLoadingView(),
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
    final currentProfile = ref.watch(profileProvider);
    final currentUserId =
        currentProfile?.id ?? ref.watch(currentUserProvider)?.id;
    final isOwner =
        currentUserId != null &&
        report.createdById != null &&
        report.createdById == currentUserId;
    final heroImage = report.imageUrls.isNotEmpty
        ? report.imageUrls.first
        : report.imagePath;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: heroImage.isNotEmpty ? 320 : 160,
            pinned: true,
            stretch: true,
            backgroundColor: context.semantic.surfaceHeader,
            foregroundColor: context.semantic.textOnPrimary,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroImage.isNotEmpty)
                    CachedAppImage(
                      imagePath: heroImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          gradient: context.heroGradient,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(gradient: context.heroGradient),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.screenHorizontal,
                    left: AppSpacing.screenHorizontal,
                    bottom: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          report.title,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.headlineSmall?.copyWith(
                            color: context.semantic.textOnPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StatusRow(report: report),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'مشاركة',
                onPressed: () => _share(report),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'تعديل الظهور',
                  onPressed: () => _showVisibilitySheet(report),
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'حذف البلاغ',
                  onPressed: () => _confirmDelete(report),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                _DetailCard(
                  child: _OverviewSection(report: report, isOwner: isOwner),
                ),
                if (report.fullDescription.isNotEmpty ||
                    report.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailCard(child: _DescriptionSection(report: report)),
                ],
                if (report.latitude != 0 || report.longitude != 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailCard(child: _MapSection(report: report)),
                ],
                if (report.attachments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(
                          icon: Icons.photo_library_outlined,
                          label: 'المرفقات',
                          trailing: '${report.attachments.length}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ReportAttachmentGallery(
                          attachments: report.attachments,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: LikeButton(reportId: report.id),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: CommentSection(
                    key: _commentSectionKey,
                    reportId: report.id,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
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
                color: context.semantic.borderStrong,
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
                leading: Icon(opt.icon, color: context.colors.primary),
                title: Text(opt.label, textDirection: TextDirection.rtl),
                trailing:
                    report.visibility?.toLowerCase() == opt.value.toLowerCase()
                    ? Icon(Icons.check, color: context.colors.primary)
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل التحديث: $e')));
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
              backgroundColor: context.semantic.error,
              foregroundColor: context.semantic.textOnPrimary,
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
            backgroundColor: context.semantic.error,
          ),
        );
      }
    }
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.report, required this.isOwner});

  final ReportModel report;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReporterSection(report: report, isOwner: isOwner),
        const SizedBox(height: AppSpacing.md),
        Divider(color: context.semantic.borderSubtle.withValues(alpha: 0.7)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          textDirection: TextDirection.rtl,
          children: [
            if (report.categoryName != null)
              _InfoTile(
                icon: Icons.category_outlined,
                label: 'التصنيف',
                value: report.categoryName!,
              ),
            if (report.subCategoryName != null)
              _InfoTile(
                icon: Icons.label_outline,
                label: 'التصنيف الفرعي',
                value: report.subCategoryName!,
              ),
            _InfoTile(
              icon: Icons.access_time_rounded,
              label: 'تاريخ الإرسال',
              value: report.submittedAgo.isNotEmpty
                  ? report.submittedAgo
                  : 'الآن',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.semantic.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: context.text.labelSmall?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
                Text(
                  value,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              trailing!,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.semantic.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.semantic.borderSubtle),
          boxShadow: context.cardShadows,
        ),
        child: child,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [_Chip(label: report.statusLabel, color: report.statusColor)],
    );
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
        : (reporterName?.trim().isNotEmpty == true
              ? reporterName!.trim()
              : 'مُبلّغ');
    final photoUrl = report.reporter?.resolvedPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            context.colors.primary.withValues(alpha: 0.08),
            context.semantic.chipBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: context.colors.primary.withValues(alpha: 0.15),
            child: isMasked
                ? Icon(Icons.person_off_outlined, color: context.colors.primary)
                : photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: CachedAppImage(
                      imagePath: photoUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: Icon(
                        Icons.person_outline,
                        color: context.colors.primary,
                      ),
                    ),
                  )
                : Icon(Icons.person_outline, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'المُبلِّغ',
                  style: context.text.labelSmall?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (report.visibility != null)
            _Chip(
              label: _visibilityLabel(report.visibility!),
              color: context.colors.primary,
              icon: _visibilityIcon(report.visibility!),
            ),
        ],
      ),
    );
  }

  String _visibilityLabel(String v) {
    switch (v.toLowerCase()) {
      case 'public':
        return 'عام';
      case 'anonymous':
        return 'مجهول';
      case 'confidential':
        return 'سري';
      default:
        return v;
    }
  }

  IconData _visibilityIcon(String v) {
    switch (v.toLowerCase()) {
      case 'anonymous':
        return Icons.person_off_outlined;
      case 'confidential':
        return Icons.lock_outline;
      default:
        return Icons.public;
    }
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final text = report.fullDescription.isNotEmpty
        ? report.fullDescription
        : report.description;
    if (text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _SectionLabel(label: 'الوصف'),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          text,
          textDirection: TextDirection.rtl,
          style: context.text.bodyMedium?.copyWith(
            height: 1.6,
            color: context.semantic.textMuted,
          ),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.map_outlined, size: 18, color: context.colors.primary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'الموقع',
              textDirection: TextDirection.rtl,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (report.displayLocation != null &&
            report.displayLocation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  report.displayLocation!,
                  textDirection: TextDirection.rtl,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
              ),
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
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('فتح الخريطة'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.semantic.borderSubtle),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 180,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: latLng,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('report'),
                      position: latLng,
                    ),
                  },
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
          ),
        ),
      ],
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
      backgroundColor: context.colors.surface,
      appBar: AppBar(backgroundColor: context.semantic.surfaceHeader),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: context.semantic.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
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
      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
