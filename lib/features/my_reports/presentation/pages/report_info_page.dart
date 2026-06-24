import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../../reports/domain/attachment_model.dart';

class ReportInfoPage extends StatefulWidget {
  const ReportInfoPage({
    super.key,
    required this.title,
    required this.submittedAgo,
    required this.description,
    required this.reportType,

    /// All attachments (images/videos) for this report.
    /// Falls back to [legacyImagePath] if empty.
    this.attachments = const [],

    /// Legacy single image path for backward compat with local/unsynced reports.
    this.legacyImagePath = '',
    required this.progressIndex,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
  });

  final String title;
  final String submittedAgo;
  final String description;
  final String reportType;
  final List<AttachmentModel> attachments;
  final String legacyImagePath;
  final int progressIndex;
  final double latitude;
  final double longitude;
  final String? locationAddress;

  @override
  State<ReportInfoPage> createState() => _ReportInfoPageState();
}

class _ReportInfoPageState extends State<ReportInfoPage> {
  int _currentImageIndex = 0;

  /// Effective list of image URLs to display.
  /// Uses attachments if available, otherwise wraps legacyImagePath.
  List<String> get _imageUrls {
    if (widget.attachments.isNotEmpty) {
      return widget.attachments
          .map((a) => a.fullUrl)
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (widget.legacyImagePath.trim().isNotEmpty) {
      return [widget.legacyImagePath];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final images = _imageUrls;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 272,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MapScreen(
                        initialTarget: LatLng(
                          widget.latitude,
                          widget.longitude,
                        ),
                        initialZoom: 15,
                        markers: {
                          Marker(
                            markerId: const MarkerId('report-location-marker'),
                            position: LatLng(widget.latitude, widget.longitude),
                            infoWindow: InfoWindow(
                              title: widget.title,
                              snippet: widget.locationAddress,
                            ),
                          ),
                        },
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 16,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: context.colors.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          widget.submittedAgo,
                          textDirection: TextDirection.rtl,
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProgressTimeline(currentStep: widget.progressIndex),
                  ],
                ),
              ),
              // Attachment gallery
              if (images.isNotEmpty)
                _AttachmentGallery(
                  imageUrls: images,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                )
              else
                Container(
                  height: 148,
                  color: context.semantic.chipBackground,
                  child: Icon(
                    Icons.image_not_supported,
                    color: context.semantic.textMuted,
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      label: 'الوصف',
                      value: widget.description,
                      valueMaxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'نوع البلاغ', value: widget.reportType),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'الموقع',
                      value:
                          widget.locationAddress ??
                          '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                      valueMaxLines: 3,
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

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.currentStep});

  final int currentStep;

  static const List<String> _statusLabels = [
    'تم الاستلام',
    'قيد المراجعه',
    'قيد المعالجه',
    'تم الحل',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < _statusLabels.length; i++) ...[
              _StepDot(isDone: i <= currentStep),
              if (i < _statusLabels.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.semantic.borderStrong,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            for (var i = 0; i < _statusLabels.length; i++)
              Expanded(
                child: Text(
                  _statusLabels[i],
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AttachmentGallery extends StatelessWidget {
  const _AttachmentGallery({
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> imageUrls;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return CachedAppImage(
                imagePath: imageUrls[index],
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: context.semantic.chipBackground,
                  child: Icon(
                    Icons.image_not_supported,
                    color: context.semantic.textMuted,
                  ),
                ),
              );
            },
          ),
          if (imageUrls.length > 1)
            Positioned(
              bottom: AppSpacing.xs,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 12 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? context.semantic.textOnPrimary
                          : context.semantic.textOnPrimary.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.semantic.borderStrong),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? context.colors.primary : Colors.transparent,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueMaxLines = 1,
  });

  final String label;
  final String value;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          '$label :',
          textDirection: TextDirection.rtl,
          style: context.text.titleSmall?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyLarge?.copyWith(
              color: context.semantic.textMuted,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
