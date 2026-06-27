import 'dart:async';
import 'dart:math' show sqrt;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../../domain/report_map_pin.dart';
import '../providers/map_notifier.dart';
import 'map_page.dart';

final nearbyPinsProvider = Provider<List<ReportMapPin>>((ref) {
  final mapState = ref.watch(mapProvider);
  final locState = ref.watch(liveLocationProvider);

  final pos = locState.currentPosition;
  if (pos == null) return mapState.pins.take(10).toList();

  const maxDistKm = 5.0;

  double distKm(ReportMapPin pin) {
    const latDeg = 111.0;
    const lonDeg = 111.320;
    final dlat = (pin.latitude - pos.latitude) * latDeg;
    final dlon = (pin.longitude - pos.longitude) * lonDeg;
    return sqrt(dlat * dlat + dlon * dlon);
  }

  return mapState.pins.where((p) => distKm(p) <= maxDistKm).toList()
    ..sort((a, b) => distKm(a).compareTo(distKm(b)));
});

class YourLocationPage extends ConsumerStatefulWidget {
  const YourLocationPage({super.key});

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
    final locState = ref.watch(liveLocationProvider);
    final nearbyPins = ref.watch(nearbyPinsProvider);
    final mapState = ref.watch(mapProvider);
    final topPadding = MediaQuery.paddingOf(context).top;

    _tryAnimateCamera(locState);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: context.semantic.surfaceHeader,
            foregroundColor: context.semantic.textOnPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMapLayer(locState, nearbyPins),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.screenHorizontal,
                    right: AppSpacing.screenHorizontal,
                    bottom: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              color: context.semantic.textOnPrimary,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'موقعي',
                                textDirection: TextDirection.rtl,
                                style: context.text.headlineSmall?.copyWith(
                                  color: context.semantic.textOnPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Material(
                          color: context.semantic.textOnPrimary.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MapPage(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Icon(
                                    Icons.open_in_full_rounded,
                                    color: context.semantic.textOnPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    'افتح الخريطة الكاملة',
                                    style: context.text.labelMedium?.copyWith(
                                      color: context.semantic.textOnPrimary,
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.semantic.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(color: context.semantic.borderSubtle),
                  boxShadow: context.cardShadows,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: context.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${nearbyPins.length}',
                        style: context.text.headlineSmall?.copyWith(
                          color: context.semantic.textOnPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'في هذه المنطقة',
                            textDirection: TextDirection.rtl,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            locState.currentPosition != null
                                ? 'بلاغات ضمن نطاق ٥ كم من موقعك'
                                : 'فعّل الموقع لعرض البلاغات القريبة',
                            textDirection: TextDirection.rtl,
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mapState.isLoading)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.primary,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () =>
                            ref.read(mapProvider.notifier).refresh(),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: context.colors.primary,
                        ),
                        tooltip: 'تحديث',
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (mapState.isLoading && nearbyPins.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (nearbyPins.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: const _EmptyNearby(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final pin = nearbyPins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _NearbyReportCard(
                      pin: pin,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportDetailPage(reportId: pin.id),
                        ),
                      ),
                    ),
                  );
                }, childCount: nearbyPins.take(15).length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapLayer(
    LiveLocationState state,
    List<ReportMapPin> nearbyPins,
  ) {
    if (state.canShowMap && state.currentPosition != null) {
      final currentLatLng = LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );

      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('your-location-live-marker'),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
        ...nearbyPins.map(
          (pin) => Marker(
            markerId: MarkerId('pin-${pin.id}'),
            position: LatLng(pin.latitude, pin.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(_pinHue(pin.status)),
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
          onMapCreated: (controller) => _mapController = controller,
        ),
      );
    }

    if (state.isLoading) {
      return ColoredBox(
        color: context.semantic.surfaceHeader,
        child: Center(
          child: CircularProgressIndicator(
            color: context.semantic.textOnPrimary,
          ),
        ),
      );
    }

    return ColoredBox(
      color: context.semantic.surfaceHeader,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: context.semantic.textOnPrimary.withValues(alpha: 0.6),
              size: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.accessStatus == LocationAccessStatus.serviceDisabled
                  ? 'يرجى تشغيل GPS لعرض الخريطة'
                  : 'تعذر تحميل الموقع',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: context.semantic.textOnPrimary.withValues(alpha: 0.75),
              ),
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

class _EmptyNearby extends StatelessWidget {
  const _EmptyNearby();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: context.semantic.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد بلاغات قريبة',
            textDirection: TextDirection.rtl,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'لم يتم العثور على بلاغات في نطاق ٥ كم من موقعك',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyReportCard extends StatelessWidget {
  const _NearbyReportCard({required this.pin, required this.onTap});

  final ReportMapPin pin;
  final VoidCallback onTap;

  Color get _statusColor => switch (pin.status.toLowerCase()) {
    'underreview' => const Color(0xFFF59E0B),
    'dispatched' => const Color(0xFF3B82F6),
    'resolved' => const Color(0xFF22C55E),
    'rejected' => const Color(0xFFEF4444),
    _ => const Color(0xFF0B6E99),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.semantic.borderSubtle),
            boxShadow: context.cardShadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pin.title,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        _statusLabel,
                        style: context.text.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: context.semantic.borderSubtle.withValues(alpha: 0.6),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  textDirection: TextDirection.rtl,
                  children: [
                    if (pin.categoryName.isNotEmpty)
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: pin.categoryName,
                      ),
                    if (pin.timeAgo.isNotEmpty)
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: pin.timeAgo,
                      ),
                    if (pin.locationName != null &&
                        pin.locationName!.isNotEmpty)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: pin.locationName!,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 14, color: context.semantic.textMuted),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
