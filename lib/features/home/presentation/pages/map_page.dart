import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../home/domain/report_map_pin.dart';
import '../../../home/presentation/providers/categories_provider.dart';
import '../../../home/presentation/providers/map_notifier.dart';
import '../../../home/presentation/providers/map_state.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_report_page.dart';

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _statusColor(String status) {
  return switch (status.toLowerCase()) {
    'underreview' => const Color(0xFFF59E0B),
    'dispatched' => const Color(0xFF3B82F6),
    'resolved' => const Color(0xFF22C55E),
    'rejected' => const Color(0xFFEF4444),
    _ => const Color(0xFF0099FF),
  };
}

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'underreview' => 'قيد المراجعة',
    'dispatched' => 'موزع',
    'resolved' => 'تم الحل',
    'rejected' => 'مرفوض',
    _ => status,
  };
}

double _statusHue(String status) {
  return switch (status.toLowerCase()) {
    'underreview' => BitmapDescriptor.hueYellow,
    'dispatched' => BitmapDescriptor.hueBlue,
    'resolved' => BitmapDescriptor.hueGreen,
    'rejected' => BitmapDescriptor.hueRed,
    _ => BitmapDescriptor.hueOrange,
  };
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with SingleTickerProviderStateMixin {
  static const _cairoCenter = LatLng(30.0444, 31.2357);
  static const _defaultZoom = 12.0;

  GoogleMapController? _mapController;
  late final AnimationController _sheetAnim;

  bool _sheetVisible = false;

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _selectPin(ReportMapPin? pin) {
    ref.read(mapProvider.notifier).selectPin(pin);
    if (pin != null) {
      setState(() => _sheetVisible = true);
      _sheetAnim.forward();
      // Animate map to pin
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pin.latitude, pin.longitude),
          15,
        ),
      );
    } else {
      _sheetAnim.reverse().whenComplete(() {
        if (mounted) setState(() => _sheetVisible = false);
      });
    }
  }

  Future<void> _onMyLocation() async {
    final success = await ref.read(mapProvider.notifier).locateMe();
    if (!mounted) return;
    if (success) {
      final s = ref.read(mapProvider);
      if (s.hasUserLocation && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(s.userLatitude!, s.userLongitude!),
            15,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر الوصول إلى موقعك. يرجى تفعيل الموقع.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        onApply: (categoryId, status) {
          Navigator.of(context).pop();
          ref.read(mapProvider.notifier).applyFilter(
                categoryId: categoryId,
                status: status,
              );
        },
        onClear: () {
          Navigator.of(context).pop();
          ref.read(mapProvider.notifier).clearFilters();
        },
        currentState: ref.read(mapProvider),
      ),
    );
  }

  Set<Marker> _buildMarkers(MapState s) {
    final markers = <Marker>{};

    // Report pins
    for (final pin in s.pins) {
      final isSelected = s.selectedPin?.id == pin.id;
      markers.add(
        Marker(
          markerId: MarkerId(pin.id),
          position: LatLng(pin.latitude, pin.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_statusHue(pin.status)),
          infoWindow: InfoWindow(
            title: pin.title,
            snippet: _statusLabel(pin.status),
          ),
          zIndexInt: isSelected ? 2 : 1,
          onTap: () => _selectPin(pin),
        ),
      );
    }

    // User location blue dot
    if (s.hasUserLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('_user_location'),
          position: LatLng(s.userLatitude!, s.userLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
          zIndexInt: 3,
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mapProvider);
    final selectedNavIndex = ref.watch(homeNavigationProvider);

    final markers = _buildMarkers(s);

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _cairoCenter,
              zoom: _defaultZoom,
            ),
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            style: context.isDarkMode ? _darkMapStyle : null,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (_) => _selectPin(null),
          ),

          // ── Top bar ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: _MapTopBar(
              isLoading: s.isLoading,
              hasFilter: s.hasActiveFilter,
              onBack: () => Navigator.of(context).pop(),
              onRefresh: () => ref.read(mapProvider.notifier).refresh(),
              onFilter: _openFilterSheet,
            ),
          ),

          // ── FABs ──────────────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            bottom: _sheetVisible ? 230.0 : 24.0,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  onTap: _onMyLocation,
                ),
                const SizedBox(height: AppSpacing.sm - 2),
                _MapFab(
                  icon: s.hasActiveFilter
                      ? Icons.filter_list_rounded
                      : Icons.tune_rounded,
                  onTap: _openFilterSheet,
                  badge: s.hasActiveFilter,
                ),
              ],
            ),
          ),

          // ── Error banner ──────────────────────────────────────────────
          if (s.error != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.semantic.error,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: context.semantic.textOnPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        s.error!,
                        style: TextStyle(
                          color: context.semantic.textOnPrimary,
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(mapProvider.notifier).refresh(),
                      child:
                          Icon(Icons.refresh, color: context.semantic.textOnPrimary, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          // ── Pin detail sheet ──────────────────────────────────────────
          if (_sheetVisible && s.selectedPin != null)
            Positioned.fill(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _sheetAnim,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _PinDetailSheet(
                    pin: s.selectedPin!,
                    onClose: () => _selectPin(null),
                    onViewDetail: () {
                      _selectPin(null);
                      Navigator.of(context).pushNamed(
                        AppRoutes.reportDetail,
                        arguments: s.selectedPin!.id,
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedNavIndex,
        onTap: (index) {
          ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
          navigateFromBottomNav(context, ref, index);
        },
        onReportTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddReportPage()),
          );
        },
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.isLoading,
    required this.hasFilter,
    required this.onBack,
    required this.onRefresh,
    required this.onFilter,
  });

  final bool isLoading;
  final bool hasFilter;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final bg = semantic.surfaceNavBar.withValues(alpha: 0.92);
    final fg = context.colors.onSurface;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.cardShadows,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded, color: fg, size: 18),
            onPressed: onBack,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: const BoxConstraints(),
          ),
          Icon(Icons.map_rounded, color: context.colors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'خريطة البلاغات',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (hasFilter)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'فلتر مفعل',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: fg, size: 20),
            onPressed: onRefresh,
            tooltip: 'تحديث',
          ),
        ],
      ),
    );
  }
}

// ─── FAB button ───────────────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final fg = context.colors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: semantic.surfaceNavBar,
          shape: BoxShape.circle,
          boxShadow: context.cardShadows,
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: fg, size: 22)),
            if (badge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Pin detail sheet ─────────────────────────────────────────────────────────

class _PinDetailSheet extends StatelessWidget {
  const _PinDetailSheet({
    required this.pin,
    required this.onClose,
    required this.onViewDetail,
  });

  final ReportMapPin pin;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final fg = context.colors.onSurface;
    final sub = semantic.textMuted;

    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: semantic.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
          boxShadow: context.cardShadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status + category row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: sub, size: 20),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusChip(status: pin.status),
                          const SizedBox(width: 8),
                          Text(
                            pin.categoryName,
                            style: TextStyle(
                              fontSize: 13,
                              color: sub,
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    pin.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pin.timeAgo.isNotEmpty)
                        Text(
                          pin.timeAgo,
                          style: TextStyle(fontSize: 12, color: sub),
                        ),
                      if (pin.locationName != null &&
                          pin.locationName!.isNotEmpty) ...[
                        Text(' • ', style: TextStyle(color: sub)),
                        Flexible(
                          child: Text(
                            pin.locationName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: 12, color: sub),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // View detail button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onViewDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.semantic.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.onApply,
    required this.onClear,
    required this.currentState,
  });

  final void Function(String? categoryId, String? status) onApply;
  final VoidCallback onClear;
  final MapState currentState;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _selectedCategoryId;
  String? _selectedStatus;

  static const _statuses = [
    ('UnderReview', 'قيد المراجعة'),
    ('Dispatched', 'موزع'),
    ('Resolved', 'تم الحل'),
    ('Rejected', 'مرفوض'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.currentState.filterCategoryId;
    _selectedStatus = widget.currentState.filterStatus;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final fg = context.colors.onSurface;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: semantic.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onClear,
                  child: Text(
                    'مسح الفلاتر',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: context.semantic.error),
                  ),
                ),
                Text(
                  'فلترة البلاغات',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Category section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الفئة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: categoriesAsync.when(
              loading: () => const Center(
                child:
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => const Center(child: Text('خطأ')),
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                reverse: true,
                children: cats.map((cat) {
                  final selected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(cat.name, textDirection: TextDirection.rtl),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _selectedCategoryId = selected ? null : cat.id;
                      }),
                      selectedColor: context.colors.primary.withValues(alpha: 0.16),
                      checkmarkColor: context.colors.primary,
                      labelStyle: TextStyle(
                        color: selected ? context.colors.primary : fg,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الحالة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              reverse: true,
              children: _statuses.map((entry) {
                final (value, label) = entry;
                final selected = _selectedStatus == value;
                final color = _statusColor(value);
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(label, textDirection: TextDirection.rtl),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedStatus = selected ? null : value;
                    }),
                    selectedColor: color.withValues(alpha: 0.16),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      color: selected ? color : fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    widget.onApply(_selectedCategoryId, _selectedStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.semantic.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'تطبيق الفلاتر',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Optional dark map style (Google Maps JSON) ───────────────────────────────

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1230"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';
