import 'dart:io';

import 'package:flutter/material.dart';

import '../network/api_config.dart';

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

    // If path is completely empty, show error
    if (trimmedPath.isEmpty) {
      print('CachedAppImage: imagePath is empty');
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    // Handle network URLs (http, https)
    if (_isNetworkUrl(trimmedPath)) {
      final resolvedUrl = _resolveNetworkUrl(trimmedPath);
      print('CachedAppImage: Network URL - "$trimmedPath" → "$resolvedUrl"');

      // Don't try to load if resolved URL is still empty
      if (resolvedUrl.trim().isEmpty) {
        print('CachedAppImage: Resolved URL is empty, showing error');
        return errorWidget ?? const Icon(Icons.image_not_supported);
      }

      return Image.network(
        resolvedUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return placeholder ??
              const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('CachedAppImage: Network image error - $error');
          return errorWidget ?? const Icon(Icons.image_not_supported);
        },
      );
    }

    // Handle local files
    if (_looksLikeLocalFile(trimmedPath)) {
      final normalized = trimmedPath.startsWith('file://')
          ? Uri.parse(trimmedPath).toFilePath()
          : trimmedPath;
      print('CachedAppImage: Local file - "$trimmedPath" → "$normalized"');

      final file = File(normalized);
      if (!file.existsSync()) {
        print('CachedAppImage: Local file does not exist - $normalized');
        return errorWidget ?? const Icon(Icons.image_not_supported);
      }

      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print('CachedAppImage: File image error - $error');
          return errorWidget ?? const Icon(Icons.image_not_supported);
        },
      );
    }

    // Handle asset images (assets/...)
    print('CachedAppImage: Asset image - "$trimmedPath"');
    return Image.asset(
      trimmedPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        print('CachedAppImage: Asset image error - $error');
        return errorWidget ?? const Icon(Icons.image_not_supported);
      },
    );
  }

  bool _isNetworkUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return true;
    }

    if (path.startsWith('assets/')) {
      return false;
    }

    if (path.startsWith('file://')) {
      return false;
    }

    if (path.startsWith('/')) {
      return !_looksLikeLocalFile(path);
    }

    return true;
  }

  bool _looksLikeLocalFile(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('file://') ||
        lower.startsWith('/data/') ||
        lower.startsWith('/storage/') ||
        lower.startsWith('/sdcard/') ||
        lower.startsWith('/mnt/') ||
        lower.startsWith('/var/') ||
        lower.startsWith('/private/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
  }

  String _resolveNetworkUrl(String path) {
    // Already absolute URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Get base URL and remove trailing slash if present
    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    // Encode the relative path
    final encodedPath = _encodePathSegments(path);

    // Combine base URL with encoded path
    return '$baseUrl$encodedPath';
  }

  String _encodePathSegments(String path) {
    if (path.isEmpty) return '';

    final trimmed = path.trim();
    final hasLeadingSlash = trimmed.startsWith('/');
    final hasTrailingSlash = trimmed.endsWith('/') && trimmed.length > 1;

    // Split by /, encode each segment, rejoin
    final segments = trimmed.split('/').where((s) => s.isNotEmpty).map((
      segment,
    ) {
      // Normalize: decode first (in case partially encoded), then encode
      try {
        segment = Uri.decodeComponent(segment);
      } catch (_) {
        // If decode fails, use original segment
      }
      return Uri.encodeComponent(segment);
    }).toList();

    var result = segments.join('/');
    if (hasLeadingSlash) result = '/$result';
    if (hasTrailingSlash) result = '$result/';

    return result;
  }
}
