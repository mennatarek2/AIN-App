import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extensions.dart';

/// A persistent [MaterialBanner] shown when the user joined a community
/// but has not yet set their GPS location.
///
/// Usage — call [LocationPendingBanner.show] to display via [ScaffoldMessenger]
/// and [ScaffoldMessenger.hideCurrentMaterialBanner] to dismiss it.
class LocationPendingBanner {
  const LocationPendingBanner._();

  /// Shows the banner on the nearest [ScaffoldMessenger].
  static void show(
    BuildContext context, {
    required VoidCallback onSetLocation,
  }) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: const Text(
          'شارك موقعك لتفعيل ميزات نداءات الاستغاثة (SOS).',
          textDirection: TextDirection.rtl,
        ),
        leading: const Icon(Icons.location_off, color: Colors.orange),
        backgroundColor: Colors.orange.shade50,
        dividerColor: Colors.orange.shade200,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              onSetLocation();
            },
            child: Text(
              'تحديد الموقع',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: Text(
              'لاحقاً',
              style: TextStyle(
                color: Colors.orange.shade600.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hides the currently visible banner (if any).
  static void hide(BuildContext context) =>
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
}

/// Inline fallback card variant — used when the banner cannot be shown via
/// ScaffoldMessenger (e.g. within a scrolling list body).
class LocationPendingBannerCard extends StatelessWidget {
  const LocationPendingBannerCard({
    super.key,
    required this.onShareLocation,
    required this.onDismiss,
  });

  final VoidCallback onShareLocation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_off, color: Colors.orange, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شارك موقعك لتفعيل ميزات SOS.',
                    textDirection: TextDirection.rtl,
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      TextButton(
                        onPressed: onShareLocation,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.orange.shade800,
                        ),
                        child: const Text('تحديد الموقع'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onDismiss,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.orange.shade400,
                        ),
                        child: const Text('لاحقاً'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: Colors.orange.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
