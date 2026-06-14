import 'package:flutter/material.dart';

import '../../domain/attachment_model.dart';

/// Fullscreen pinch-to-zoom photo viewer.
///
/// Opened when the user taps an image in [ReportAttachmentGallery].
/// Supports swiping between multiple images via [PageView].
class FullscreenPhotoPage extends StatefulWidget {
  const FullscreenPhotoPage({
    super.key,
    required this.attachments,
    this.initialIndex = 0,
  });

  final List<AttachmentModel> attachments;
  final int initialIndex;

  @override
  State<FullscreenPhotoPage> createState() => _FullscreenPhotoPageState();
}

class _FullscreenPhotoPageState extends State<FullscreenPhotoPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.attachments.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.attachments.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final attachment = widget.attachments[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Hero(
                tag: 'attachment_${attachment.id}',
                child: Image.network(
                  attachment.fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stack) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'تعذر تحميل الصورة',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
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
