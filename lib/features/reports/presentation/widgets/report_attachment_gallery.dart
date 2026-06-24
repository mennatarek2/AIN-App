import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/attachment_model.dart';
import '../pages/fullscreen_photo_page.dart';

/// Determines the media type of an attachment by its file extension.
enum _AttachmentType { image, video, file }

_AttachmentType _typeOf(AttachmentModel a) {
  if (a.isImage) return _AttachmentType.image;

  final lower = a.fileName.toLowerCase();
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.webm')) {
    return _AttachmentType.video;
  }
  return _AttachmentType.file;
}

/// Renders the attachment gallery for a report detail screen.
///
/// - Images: horizontal scroll with tappable thumbnails → fullscreen viewer
/// - Videos: inline [VideoPlayer] with play/pause
/// - Files: download row
class ReportAttachmentGallery extends StatelessWidget {
  const ReportAttachmentGallery({super.key, required this.attachments});

  final List<AttachmentModel> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments
        .where((a) => _typeOf(a) == _AttachmentType.image)
        .toList();
    final videos = attachments
        .where((a) => _typeOf(a) == _AttachmentType.video)
        .toList();
    final files = attachments
        .where((a) => _typeOf(a) == _AttachmentType.file)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) _ImageGallery(images: images),
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...videos.map((v) => _VideoAttachment(attachment: v)),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...files.map((f) => _FileRow(attachment: f)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image gallery
// ---------------------------------------------------------------------------

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});
  final List<AttachmentModel> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 520 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final attachment = images[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenPhotoPage(
                      attachments: images,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'attachment_${attachment.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        attachment.fullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: context.semantic.chipBackground,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ),
                      if (images.length > 1 && index == 0)
                        Positioned(
                          left: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.semantic.overlay,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '+${images.length - 1}',
                              style: TextStyle(
                                color: context.semantic.textOnPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Video player
// ---------------------------------------------------------------------------

class _VideoAttachment extends StatefulWidget {
  const _VideoAttachment({required this.attachment});
  final AttachmentModel attachment;

  @override
  State<_VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<_VideoAttachment> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.attachment.fullUrl),
    )..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _initialized
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )
            : Container(
                height: 180,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// File download row
// ---------------------------------------------------------------------------

class _FileRow extends StatelessWidget {
  const _FileRow({required this.attachment});
  final AttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xxs,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.semantic.borderSubtle),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: ListTile(
          leading: Icon(
            Icons.attach_file_rounded,
            color: context.colors.primary,
          ),
          title: Text(
            attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          trailing: IconButton(
            tooltip: 'تحميل',
            icon: Icon(
              Icons.download_rounded,
              color: context.colors.primary,
            ),
            onPressed: () async {
              final uri = Uri.parse(attachment.fullUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      ),
    );
  }
}
