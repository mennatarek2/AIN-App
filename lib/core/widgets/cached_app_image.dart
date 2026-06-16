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
    this.headers,
  });

  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? headers;

  /// Headers for loading images from the API (auth + ngrok).
  static Map<String, String> apiImageHeaders({String? token}) {
    final result = <String, String>{
      'Accept': 'image/*',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null && token.trim().isNotEmpty) {
      result['Authorization'] = 'Bearer ${token.trim()}';
    }
    return result;
  }

  static bool isNetworkPath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return true;
    }
    if (trimmed.startsWith('assets/') || trimmed.startsWith('file://')) {
      return false;
    }
    if (trimmed.startsWith('/')) {
      return !isLocalDevicePath(trimmed);
    }
    return trimmed.isNotEmpty;
  }

  static bool isLocalDevicePath(String path) {
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

  static String resolveNetworkUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return normalizeApiHost(trimmed);
    }

    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final encodedPath = _encodePathSegments(trimmed);
    return normalizeApiHost('$baseUrl$encodedPath');
  }

  /// Rewrites localhost/loopback hosts to the configured API base URL.
  static String normalizeApiHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final host = uri.host.toLowerCase();
    if (host != 'localhost' &&
        host != '127.0.0.1' &&
        host != '10.0.2.2') {
      return url;
    }

    final base = Uri.tryParse(ApiConfig.baseUrl);
    if (base == null || base.host.isEmpty) return url;

    return uri
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        )
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath.trim();

    // If path is completely empty, show error
    if (trimmedPath.isEmpty) {
      print('CachedAppImage: imagePath is empty');
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    // Handle network URLs (http, https)
    if (isNetworkPath(trimmedPath)) {
      final resolvedUrl = resolveNetworkUrl(trimmedPath);
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
        headers: headers ?? apiImageHeaders(),
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
    if (isLocalDevicePath(trimmedPath)) {
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

  static String _encodePathSegments(String path) {
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
