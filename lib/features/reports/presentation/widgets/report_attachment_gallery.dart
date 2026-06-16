import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

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
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
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
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  attachment.fullUrl,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 180,
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isDark ? const Color(0xFF2A3580) : const Color(0xFFD1D9F0),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF0099FF)),
          title: Text(
            attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFF3F6F9) : const Color(0xFF060C3A),
            ),
          ),
          trailing: IconButton(
            tooltip: 'تحميل',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0099FF)),
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
