import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';

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

  static const List<_LocationCardData> _cards = [
    _LocationCardData(
      top: 376,
      title: 'حادث سير',
      subtitle: 'حادث اصطدام سيارة ملاكي بعمود إنارة...',
      status: 'تم الحل',
      statusColor: Color(0xFF35A933),
      imageUrl: 'assets/images/report_image.png',
    ),
    _LocationCardData(
      top: 480,
      title: 'حريق',
      subtitle: 'يوجد حريق في الشارع، مع وجود نيران...',
      status: 'قيد المعالجة',
      statusColor: Color(0xFF33A3F0),
      imageUrl: 'assets/images/report_image.png',
    ),
    _LocationCardData(
      top: 584,
      title: 'تلف إشارة مرور',
      subtitle: 'توجد إشارة مرور تالفة ولا تعمل بشكل...',
      status: 'قيد المراجعة',
      statusColor: Color(0xFFF0BE33),
      imageUrl: 'assets/images/report_image.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveLocationProvider.notifier).startTracking();
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
    final state = ref.watch(liveLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final backIconColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    _tryAnimateCamera(state);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / YourLocationPage.designW;
          final designHeight = YourLocationPage.designH * scale;
          final canvasHeight = designHeight > constraints.maxHeight
              ? designHeight
              : constraints.maxHeight;

          double sx(double value) => value * scale;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: sx(340),
                    child: _buildTopMap(state),
                  ),
                  Positioned(
                    left: sx(16),
                    top: media.padding.top + sx(4),
                    width: sx(24),
                    height: sx(24),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: sx(20),
                        color: backIconColor,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: sx(316),
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(sx(30)),
                          topRight: Radius.circular(sx(30)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: sx(16),
                    top: sx(328),
                    width: constraints.maxWidth - sx(32),
                    child: Text(
                      'في هذه المنطقة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: sx(19),
                        fontWeight: FontWeight.w400,
                        color: titleColor,
                        height: 1,
                      ),
                    ),
                  ),
                  for (final card in _cards)
                    Positioned(
                      left: sx(16),
                      top: sx(card.top),
                      width: sx(398),
                      height: sx(92),
                      child: _LocationReportCard(card: card, scale: scale),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopMap(LiveLocationState state) {
    if (state.canShowMap && state.currentPosition != null) {
      final currentLatLng = LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );

      return MapScreen(
        initialTarget: currentLatLng,
        initialZoom: 16,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId('your-location-live-marker'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          state.accessStatus == LocationAccessStatus.serviceDisabled
              ? 'يرجى تشغيل GPS'
              : 'تعذر تحميل الموقع',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
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

class _LocationCardData {
  final double top;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String imageUrl;

  const _LocationCardData({
    required this.top,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
  });
}

class _LocationReportCard extends StatelessWidget {
  final _LocationCardData card;
  final double scale;

  const _LocationReportCard({required this.card, required this.scale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardBorderColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0x33060C3A);
    final cardTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final cardSubtitleColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0x66060C3A);
    final statusTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    double sx(double value) => value * scale;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(sx(10)),
        border: Border.all(color: cardBorderColor, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: sx(1),
            top: sx(-1),
            width: sx(88),
            height: sx(92),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(sx(10)),
              child: Image.asset(card.imageUrl, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: sx(7),
            top: sx(7),
            width: sx(96),
            height: sx(36),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x3366C8FF),
                borderRadius: BorderRadius.circular(sx(10)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.status,
                    textDirection: TextDirection.rtl,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: sx(13),
                      fontWeight: FontWeight.w400,
                      color: statusTextColor,
                    ),
                  ),
                  SizedBox(width: sx(6)),
                  Container(
                    width: sx(13),
                    height: sx(13),
                    decoration: BoxDecoration(
                      color: card.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: sx(96),
            top: sx(6),
            width: sx(208),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  card.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: sx(19),
                    fontWeight: FontWeight.w400,
                    color: cardTitleColor,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: sx(8)),
                Text(
                  card.subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  textScaler: TextScaler.noScaling,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: sx(13),
                    fontWeight: FontWeight.w400,
                    color: cardSubtitleColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
