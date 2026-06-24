import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';

class SelectReportLocationPage extends ConsumerStatefulWidget {
  const SelectReportLocationPage({super.key});

  @override
  ConsumerState<SelectReportLocationPage> createState() =>
      _SelectReportLocationPageState();
}

class _SelectReportLocationPageState
    extends ConsumerState<SelectReportLocationPage> {
  static const LatLng _cairoFallback = LatLng(30.0444, 31.2357);
  static const CameraPosition _initialCamera = CameraPosition(
    target: _cairoFallback,
    zoom: 15,
  );
  static const double _sheetTopRadius = AppRadius.xxl;

  GoogleMapController? _controller;
  CameraPosition? _pendingCamera;
  LatLng _selectedLocation = _cairoFallback;
  String _address = 'جاري تحديد الموقع...';
  bool _isLoading = true;
  bool _isResolvingAddress = false;
  LocationAccessStatus _accessStatus = LocationAccessStatus.denied;
  int _activeAddressRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePicker();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePicker() async {
    await _moveToCurrentLocation(showErrorSnackBar: false);
    await _resolveAddress(_selectedLocation);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _moveToCurrentLocation({required bool showErrorSnackBar}) async {
    final service = ref.read(locationServiceProvider);
    final cache = ref.read(locationLocalDataSourceProvider);
    final cachedLocation = await cache.getLastKnownLocation();

    final access = await service.ensureLocationAccess();
    if (!mounted) return;

    if (!access.isGranted) {
      if (cachedLocation != null) {
        _selectedLocation = LatLng(
          cachedLocation.latitude,
          cachedLocation.longitude,
        );
        _address =
            cachedLocation.address ?? _formatFallbackAddress(_selectedLocation);
        await _animateCameraTo(_selectedLocation, zoom: 16);
      }

      setState(() {
        _accessStatus = access.status;
        _isResolvingAddress = false;
      });

      if (showErrorSnackBar) {
        _showLocationError(access);
      }
      return;
    }

    final currentPosition = await service.getCurrentPosition();
    if (!mounted) return;

    if (currentPosition == null) {
      if (cachedLocation != null) {
        final target = LatLng(
          cachedLocation.latitude,
          cachedLocation.longitude,
        );
        _selectedLocation = target;
        _address = cachedLocation.address ?? _formatFallbackAddress(target);
        await _animateCameraTo(target, zoom: 16);
        setState(() {
          _accessStatus = LocationAccessStatus.granted;
        });
        return;
      }

      if (showErrorSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على موقعك الحالي حالياً')),
        );
      }
      return;
    }

    final target = LatLng(currentPosition.latitude, currentPosition.longitude);
    _selectedLocation = target;
    _accessStatus = LocationAccessStatus.granted;
    await _animateCameraTo(target, zoom: 16);
    await _resolveAddress(target);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleAccessRecoveryAction() async {
    final service = ref.read(locationServiceProvider);

    if (_accessStatus == LocationAccessStatus.serviceDisabled) {
      await service.openDeviceLocationSettings();
    } else if (_accessStatus == LocationAccessStatus.permanentlyDenied) {
      await service.openPermissionSettings();
    }

    await _moveToCurrentLocation(showErrorSnackBar: true);
  }

  String _accessHint() {
    return switch (_accessStatus) {
      LocationAccessStatus.serviceDisabled =>
        'خدمة الموقع متوقفة. فعّلها لاختيار موقع البلاغ.',
      LocationAccessStatus.permanentlyDenied =>
        'إذن الموقع مرفوض. افتح الإعدادات للسماح بالوصول.',
      LocationAccessStatus.denied => 'يرجى السماح بإذن الموقع للمتابعة.',
      LocationAccessStatus.granted => '',
    };
  }

  Future<void> _animateCameraTo(LatLng target, {double zoom = 16}) async {
    final nextCamera = CameraPosition(target: target, zoom: zoom);

    if (_controller == null) {
      _pendingCamera = nextCamera;
      return;
    }

    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(nextCamera),
    );
  }

  Future<void> _resolveAddress(LatLng target) async {
    final requestId = ++_activeAddressRequest;

    if (mounted) {
      setState(() {
        _isResolvingAddress = true;
      });
    }

    final service = ref.read(locationServiceProvider);
    final result = await service.getReadableAddress(
      latitude: target.latitude,
      longitude: target.longitude,
      localeIdentifier: 'ar',
    );

    if (!mounted || requestId != _activeAddressRequest) return;

    setState(() {
      _address = (result == null || result.trim().isEmpty)
          ? _formatFallbackAddress(target)
          : result;
      _isResolvingAddress = false;
    });

    await ref
        .read(locationLocalDataSourceProvider)
        .saveLastKnownLocation(
          latitude: target.latitude,
          longitude: target.longitude,
          address: _address,
        );
  }

  Future<void> _onCameraIdle() async {
    await _resolveAddress(_selectedLocation);
  }

  void _showLocationError(LocationAccessResult access) {
    final message = switch (access.status) {
      LocationAccessStatus.serviceDisabled => 'يرجى تشغيل خدمة الموقع أولاً',
      LocationAccessStatus.permanentlyDenied =>
        'تم رفض إذن الموقع. فعّل الإذن من إعدادات التطبيق',
      LocationAccessStatus.denied => 'يرجى السماح بإذن الموقع للمتابعة',
      LocationAccessStatus.granted => access.message ?? 'تعذر الوصول للموقع',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatFallbackAddress(LatLng target) {
    return '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomSheetHeight = 164 + safeBottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              mapType: MapType.normal,
              myLocationEnabled: _accessStatus == LocationAccessStatus.granted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              buildingsEnabled: true,
              indoorViewEnabled: true,
              onMapCreated: (controller) {
                _controller = controller;

                final cameraToApply =
                    _pendingCamera ??
                    CameraPosition(
                      target: _selectedLocation,
                      zoom: _accessStatus == LocationAccessStatus.granted
                          ? 16
                          : 15,
                    );
                _pendingCamera = null;
                controller.moveCamera(
                  CameraUpdate.newCameraPosition(cameraToApply),
                );
              },
              onCameraMove: (position) {
                _selectedLocation = position.target;
              },
              onCameraIdle: _onCameraIdle,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -24),
                child: Icon(
                  Icons.location_pin,
                  color: context.semantic.error,
                  size: 50,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _CircleShadowButton(
                    onTap: () => Navigator.of(context).pop(),
                    icon: Icons.arrow_back,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: semantic.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: context.cardShadows,
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        _isResolvingAddress
                            ? 'جاري تحديث العنوان...'
                            : _address,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: bottomSheetHeight + 16,
            child: FloatingActionButton.small(
              heroTag: 'select-report-location-my-location',
              backgroundColor: semantic.surfaceContainer,
              foregroundColor: context.colors.primary,
              onPressed: () {
                _moveToCurrentLocation(showErrorSnackBar: true);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: semantic.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_sheetTopRadius),
                ),
                boxShadow: context.cardShadows,
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl + safeBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: context.colors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _isResolvingAddress
                              ? 'جاري تحديث العنوان...'
                              : _address,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _accessStatus == LocationAccessStatus.granted
                          ? () {
                              Navigator.of(context).pop(_selectedLocation);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.semantic.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'تأكيد الموقع',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_accessStatus != LocationAccessStatus.granted) ...[
                    const SizedBox(height: 12),
                    Text(
                      _accessHint(),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: semantic.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _handleAccessRecoveryAction,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('محاولة تفعيل الموقع'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(color: context.colors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: context.semantic.overlay,
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleShadowButton extends StatelessWidget {
  const _CircleShadowButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.semantic.surfaceContainer,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, color: context.colors.onSurface),
        ),
      ),
    );
  }
}
