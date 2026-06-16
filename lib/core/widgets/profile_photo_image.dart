import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'cached_app_image.dart';

/// Displays a profile photo from a local path or authenticated API URL.
class ProfilePhotoImage extends ConsumerStatefulWidget {
  const ProfilePhotoImage({
    super.key,
    this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  static Widget defaultFallback({BoxFit fit = BoxFit.cover}) {
    return Image.asset('assets/images/user_chatbot.png', fit: fit);
  }

  @override
  ConsumerState<ProfilePhotoImage> createState() => _ProfilePhotoImageState();
}

class _ProfilePhotoImageState extends ConsumerState<ProfilePhotoImage> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNetworkImage());
  }

  @override
  void didUpdateWidget(ProfilePhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _imageBytes = null;
      _loadedPath = null;
      _loadNetworkImage();
    }
  }

  Future<void> _loadNetworkImage() async {
    final trimmed = widget.imagePath?.trim() ?? '';
    if (trimmed.isEmpty ||
        CachedAppImage.isLocalDevicePath(trimmed) ||
        !CachedAppImage.isNetworkPath(trimmed)) {
      return;
    }

    if (_isLoading || (_loadedPath == trimmed && _imageBytes != null)) return;

    setState(() => _isLoading = true);

    try {
      final token =
          await ref.read(userLocalDataSourceProvider).getCachedToken();
      final resolvedUrl = CachedAppImage.resolveNetworkUrl(trimmed);
      final response = await http.get(
        Uri.parse(resolvedUrl),
        headers: CachedAppImage.apiImageHeaders(token: token),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _loadedPath = trimmed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _imageBytes = null;
          _loadedPath = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageBytes = null;
        _loadedPath = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackWidget =
        widget.fallback ?? ProfilePhotoImage.defaultFallback(fit: widget.fit);
    final trimmed = widget.imagePath?.trim() ?? '';

    if (trimmed.isEmpty) return _sized(fallbackWidget);

    if (CachedAppImage.isLocalDevicePath(trimmed)) {
      final filePath = trimmed.startsWith('file://')
          ? Uri.parse(trimmed).toFilePath()
          : trimmed;
      final file = File(filePath);
      if (file.existsSync()) {
        return _sized(
          Image.file(
            file,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (_, __, ___) => fallbackWidget,
          ),
        );
      }
      return _sized(fallbackWidget);
    }

    if (_imageBytes != null && _loadedPath == trimmed) {
      return _sized(
        Image.memory(
          _imageBytes!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, __, ___) => fallbackWidget,
        ),
      );
    }

    if (_isLoading) {
      return _sized(
        const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _sized(fallbackWidget);
  }

  Widget _sized(Widget child) {
    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      );
    }
    return child;
  }
}
