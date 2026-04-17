import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedAppImage extends StatelessWidget {
  const CachedAppImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath.trim();

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmedPath,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) =>
            placeholder ?? const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            errorWidget ?? const Icon(Icons.image_not_supported),
      );
    }

    if (trimmedPath.startsWith('/') || trimmedPath.startsWith('file://')) {
      final normalized = trimmedPath.startsWith('file://')
          ? Uri.parse(trimmedPath).toFilePath()
          : trimmedPath;
      return Image.file(
        File(normalized),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? const Icon(Icons.image_not_supported),
      );
    }

    return Image.asset(
      trimmedPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? const Icon(Icons.image_not_supported),
    );
  }
}
