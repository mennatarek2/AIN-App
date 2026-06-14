import 'dart:async';
import 'dart:math' show sqrt;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../../domain/report_map_pin.dart';
import '../providers/map_notifier.dart';
import 'map_page.dart';

// ─── Provider: nearby pins ────────────────────────────────────────────────────

/// Returns pins within ~5 km of user's current location, sorted by distance.
final nearbyPinsProvider = Provider<List<ReportMapPin>>((ref) {
  final mapState = ref.watch(mapProvider);
  final locState = ref.watch(liveLocationProvider);

  final pos = locState.currentPosition;
  if (pos == null) return mapState.pins.take(10).toList();

  const maxDistKm = 5.0;

  double distKm(ReportMapPin pin) {
    // Flat-earth approximation (good enough for small distances)
    const latDeg = 111.0;
    const lonDeg = 111.320;
    final dlat = (pin.latitude - pos.latitude) * latDeg;
    final dlon = (pin.longitude - pos.longitude) * lonDeg;
    return sqrt(dlat * dlat + dlon * dlon);
  }

  return mapState.pins
      .where((p) => distKm(p) <= maxDistKm)
      .toList()
    ..sort((a, b) => distKm(a).compareTo(distKm(b)));
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class YourLocationPage extends ConsumerStatefulWidget {
  const YourLocationPage({super.key});

  static const double designW = 430;
  static const double designH = 932;

  @override
  ConsumerState<YourLocationPage> createState() => _YourLocationPageState();
}

class _YourLocationPageState extends ConsumerState<YourLocationPage> {
  GoogleMapController? _mapController;
  Timer? _cameraUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveLocationProvider.notifier).startTracking();
      // Also load map pins if not already loaded
      ref.read(mapProvider.notifier).loadPins();
    });
  }

  @override
  void dispose() {
    _cameraUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final locState = ref.watch(liveLocationProvider);
    final nearbyPins = ref.watch(nearbyPinsProvider);
    final mapState = ref.watch(mapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final titleColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardBg = isDark ? const Color(0xFF0D1445) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D6B) : const Color(0xFFE2E8F0);
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    _tryAnimateCamera(locState);

    final scale = MediaQuery.of(context).size.width / YourLocationPage.designW;

    double sx(double v) => v * scale;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Full-height scrollable body ──────────────────────────────────
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Mini map (clickable → full MapPage) ──────────────────
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapPage()),
                  ),
                  child: SizedBox(
                    height: sx(320),
                    child: Stack(
                      children: [
                        _buildTopMap(locState, nearbyPins),
                        // Tap-to-expand overlay label
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_full_rounded,
                                      color: Colors.white, size: 13),
                                  SizedBox(width: 5),
                                  Text(
                                    'افتح الخريطة الكاملة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── White rounded panel ──────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button row
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          media.padding.top + 12,
                          16,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E2D6B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(Icons.place_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'في هذه المنطقة',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const Spacer(),
                            if (mapState.isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              TextButton.icon(
                                onPressed: () =>
                                    ref.read(mapProvider.notifier).refresh(),
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 14, color: AppColors.primary),
                                label: const Text(
                                  'تحديث',
                                  style: TextStyle(
                                      color: AppColors.primary, fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          locState.currentPosition != null
                              ? 'أقرب ${nearbyPins.length} بلاغ في نطاق ٥ كم'
                              : 'تفعيل الموقع لعرض البلاغات القريبة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Reports list ────────────────────────────────
                      if (mapState.isLoading && nearbyPins.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (nearbyPins.isEmpty)
                        _EmptyNearby(isDark: isDark, textSecondary: textSecondary)
                      else
                        ...nearbyPins.take(15).map(
                              (pin) => Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: _PinReportCard(
                                  pin: pin,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  textSecondary: textSecondary,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ReportDetailPage(reportId: pin.id),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating back button on top of map ──────────────────────────
          Positioned(
            top: media.padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map widget ────────────────────────────────────────────────────────────

  Widget _buildTopMap(LiveLocationState state, List<ReportMapPin> nearbyPins) {
    if (state.canShowMap && state.currentPosition != null) {
      final currentLatLng = LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );

      // Build markers: user position + nearby report pins
      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('your-location-live-marker'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        ...nearbyPins.map(
          (pin) => Marker(
            markerId: MarkerId('pin-${pin.id}'),
            position: LatLng(pin.latitude, pin.longitude),
            infoWindow: InfoWindow(title: pin.title),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _pinHue(pin.status),
            ),
          ),
        ),
      };

      return AbsorbPointer(
        child: MapScreen(
          initialTarget: currentLatLng,
          initialZoom: 14,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: markers,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      );
    }

    if (state.isLoading) {
      return Container(
        color: const Color(0xFF0D1230),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0D1230),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined,
                color: Colors.white60, size: 40),
            const SizedBox(height: 12),
            Text(
              state.accessStatus == LocationAccessStatus.serviceDisabled
                  ? 'يرجى تشغيل GPS لعرض الخريطة'
                  : 'تعذر تحميل الموقع',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(liveLocationProvider.notifier)
                  .startTracking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  double _pinHue(String status) {
    return switch (status.toLowerCase()) {
      'underreview' => BitmapDescriptor.hueYellow,
      'dispatched' => BitmapDescriptor.hueBlue,
      'resolved' => BitmapDescriptor.hueGreen,
      'rejected' => BitmapDescriptor.hueRed,
      _ => BitmapDescriptor.hueOrange,
    };
  }

  void _tryAnimateCamera(LiveLocationState state) {
    if (_mapController == null || state.currentPosition == null) return;
    _cameraUpdateTimer ??= Timer(const Duration(milliseconds: 500), () {
      _cameraUpdateTimer = null;
      final latLng = LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyNearby extends StatelessWidget {
  const _EmptyNearby({required this.isDark, required this.textSecondary});

  final bool isDark;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1445) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2D6B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'لا توجد بلاغات قريبة',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'لم يتم العثور على بلاغات في نطاق ٥ كم من موقعك',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pin Report Card ──────────────────────────────────────────────────────────

class _PinReportCard extends StatelessWidget {
  const _PinReportCard({
    required this.pin,
    required this.cardBg,
    required this.cardBorder,
    required this.textSecondary,
    required this.onTap,
  });

  final ReportMapPin pin;
  final Color cardBg;
  final Color cardBorder;
  final Color textSecondary;
  final VoidCallback onTap;

  Color get _statusColor => switch (pin.status.toLowerCase()) {
    'underreview' => const Color(0xFFF59E0B),
    'dispatched' => const Color(0xFF3B82F6),
    'resolved' => const Color(0xFF22C55E),
    'rejected' => const Color(0xFFEF4444),
    _ => AppColors.primary,
  };

  String get _statusLabel => switch (pin.status.toLowerCase()) {
    'underreview' => 'قيد المراجعة',
    'dispatched' => 'موزع',
    'resolved' => 'تم الحل',
    'rejected' => 'مرفوض',
    _ => pin.status,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // Colored status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Category + Status row
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            pin.title,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: color.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        if (pin.categoryName.isNotEmpty) ...[
                          Icon(Icons.category_outlined,
                              size: 12, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            pin.categoryName,
                            style: TextStyle(
                                fontSize: 11, color: textSecondary),
                          ),
                          Text(' • ',
                              style:
                                  TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                        if (pin.timeAgo.isNotEmpty)
                          Text(
                            pin.timeAgo,
                            style:
                                TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        if (pin.locationName != null &&
                            pin.locationName!.isNotEmpty) ...[
                          Text(' • ',
                              style:
                                  TextStyle(fontSize: 11, color: textSecondary)),
                          Expanded(
                            child: Text(
                              pin.locationName!,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_left,
                  size: 16, color: textSecondary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
