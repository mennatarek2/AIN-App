import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../data/community_remote_data_source.dart';
import '../providers/communities_provider.dart';
import 'add_member_page.dart';
import 'community_notification_page.dart';
import 'member_details_page.dart';

// CommunityMember is defined in communities_provider.dart

// ─── SOS History Provider ─────────────────────────────────────────────────────

final sosHistoryProvider =
    FutureProvider.family<List<SosHistoryItem>, String>((ref, communityId) async {
  final ds = ref.watch(communityRemoteDataSourceProvider);
  return ds.fetchSosHistory(communityId);
});

// ─── Community Info Page ──────────────────────────────────────────────────────

class CommunityInfoPage extends ConsumerStatefulWidget {
  const CommunityInfoPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.members,
  });

  final String communityId;
  final String communityName;
  final List<CommunityMember> members;

  @override
  ConsumerState<CommunityInfoPage> createState() => _CommunityInfoPageState();
}

class _CommunityInfoPageState extends ConsumerState<CommunityInfoPage> {
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(communityLiveLocationProvider.notifier)
          .startTracking(currentUserCommunityId: widget.communityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveState = ref.watch(communityLiveLocationProvider);
    final users = ref.watch(communityUsersProvider(widget.communityId));
    final sosHistoryAsync = ref.watch(sosHistoryProvider(widget.communityId));
    final pageBackground = isDark ? const Color(0xFF060C3A) : AppColors.backgroundLight;
    final sectionTitleColor = isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;
    final cardBg = isDark ? const Color(0xFF0D1445) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D6B) : const Color(0xFFE5E7EB);
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Check for active SOS from state
    final commState = ref.watch(communitiesProvider);
    final activeSosCount = commState.activeSosCounts[widget.communityId] ?? 0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          _Header(
            title: widget.communityName,
            onBack: () => Navigator.of(context).pop(),
            onNotificationTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CommunityNotificationPage(),
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Active SOS Banner ────────────────────────────────────
                  if (activeSosCount > 0)
                    _ActiveSOSBanner(count: activeSosCount),

                  if (activeSosCount > 0) const SizedBox(height: 16),

                  // ── Map ──────────────────────────────────────────────────
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildCommunityMap(liveState: liveState, users: users),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Members ──────────────────────────────────────────────
                  _SectionHeader(
                    label: 'الأعضاء (${widget.members.length})',
                    color: sectionTitleColor,
                  ),
                  const SizedBox(height: 10),

                  if (widget.members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'لا يوجد أعضاء بعد',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    )
                  else ...[
                    // Avatars row
                    _MembersAvatarRow(members: widget.members),
                    const SizedBox(height: 12),
                    // Full member list
                    ...widget.members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MemberCard(
                          member: m,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MemberDetailsPage(
                                member: m,
                                lastLocation: 'غير محدد',
                                lastSeenText: 'منذ قليل',
                                activities: const [],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Add member button ────────────────────────────────────
                  _AddMemberButton(
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMemberPage(communityId: widget.communityId),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── SOS History ──────────────────────────────────────────
                  _SectionHeader(
                    label: 'سجل حوادث سابقة',
                    color: sectionTitleColor,
                  ),
                  const SizedBox(height: 10),

                  sosHistoryAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'تعذّر تحميل السجل',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    data: (history) => history.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Center(
                              child: Text(
                                'لا يوجد سجل حوادث سابقة',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: history
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _PastSOSCard(
                                        item: item,
                                        cardBg: cardBg,
                                        cardBorder: cardBorder,
                                        textSecondary: textSecondary,
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 32),

                  // ── Leave community ──────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _isLeaving ? null : _showLeaveDialog,
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'مغادرة المجتمع',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityMap({
    required CommunityLiveLocationState liveState,
    required List<LiveUserLocation> users,
  }) {
    if (users.isNotEmpty) {
      final markers = users
          .map(
            (user) => Marker(
              markerId: MarkerId(user.userId),
              position: user.latLng,
              infoWindow: InfoWindow(
                title: user.name,
                snippet: user.isCurrentUser ? 'موقعك الحالي' : 'عضو في المجتمع',
              ),
              icon: user.isCurrentUser
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          )
          .toSet();

      return MapScreen(
        initialTarget: users.first.latLng,
        initialZoom: 14,
        myLocationEnabled: liveState.accessStatus == LocationAccessStatus.granted,
        myLocationButtonEnabled: true,
        markers: markers,
      );
    }

    if (liveState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined),
              const SizedBox(height: 8),
              Text(
                liveState.accessStatus == LocationAccessStatus.serviceDisabled
                    ? 'يرجى تشغيل GPS لعرض خريطة المجتمع'
                    : (liveState.errorMessage ?? 'لا توجد بيانات مواقع حالياً'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (liveState.accessStatus == LocationAccessStatus.serviceDisabled) {
                    ref.read(communityLiveLocationProvider.notifier).openDeviceLocationSettings();
                    return;
                  }
                  if (liveState.accessStatus == LocationAccessStatus.permanentlyDenied) {
                    ref.read(communityLiveLocationProvider.notifier).openPermissionSettings();
                    return;
                  }
                  ref.read(communityLiveLocationProvider.notifier).startTracking(
                        currentUserCommunityId: widget.communityId,
                      );
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'مغادرة المجتمع',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد مغادرة "${widget.communityName}"؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('نعم، مغادرة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isLeaving = true);
    try {
      await ref.read(communitiesProvider.notifier).leaveCommunity(widget.communityId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر مغادرة المجتمع')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }
}

// ─── Active SOS Banner ────────────────────────────────────────────────────────

class _ActiveSOSBanner extends StatefulWidget {
  const _ActiveSOSBanner({required this.count});

  final int count;

  @override
  State<_ActiveSOSBanner> createState() => _ActiveSOSBannerState();
}

class _ActiveSOSBannerState extends State<_ActiveSOSBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final borderColor = Color.lerp(
          const Color(0xFFEF4444),
          const Color(0xFFFF8888),
          _ctrl.value,
        )!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.crisis_alert_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'يوجد ${widget.count > 1 ? '${widget.count} نداءات طوارئ' : 'نداء طوارئ'} نشط',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Members Avatar Row ───────────────────────────────────────────────────────

class _MembersAvatarRow extends StatelessWidget {
  const _MembersAvatarRow({required this.members});

  final List<CommunityMember> members;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 5;
    final visible = members.take(maxVisible).toList();
    final extra = members.length - maxVisible;

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            ...visible.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final color = [
                const Color(0xFF3B82F6),
                const Color(0xFF8B5CF6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                const Color(0xFFEF4444),
              ][i % 5];

              return Positioned(
                right: i * 28.0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            if (extra > 0)
              Positioned(
                right: maxVisible * 28.0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Past SOS Card ────────────────────────────────────────────────────────────

class _PastSOSCard extends StatelessWidget {
  const _PastSOSCard({
    required this.item,
    required this.cardBg,
    required this.cardBorder,
    required this.textSecondary,
  });

  final SosHistoryItem item;
  final Color cardBg;
  final Color cardBorder;
  final Color textSecondary;

  Color get _severityColor => switch (item.severity.toLowerCase()) {
    'critical' => const Color(0xFFDC2626),
    'high' => const Color(0xFFF59E0B),
    _ => const Color(0xFF3B82F6),
  };

  String get _severityLabel => switch (item.severity.toLowerCase()) {
    'critical' => 'حرج',
    'high' => 'عالي',
    _ => 'عادي',
  };

  String get _statusLabel => switch (item.status.toLowerCase()) {
    'resolved' => 'تم الحل',
    'cancelled' => 'ملغي',
    'falsealarm' => 'إنذار كاذب',
    _ => item.status,
  };

  Color get _statusColor => switch (item.status.toLowerCase()) {
    'resolved' => const Color(0xFF22C55E),
    'cancelled' => Colors.grey,
    _ => const Color(0xFFF59E0B),
  };

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'منذ قليل';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // Severity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _severityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _severityLabel,
                  style: TextStyle(
                    color: _severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(item.triggeredAt),
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          if (item.message != null && item.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.message!,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 13, color: textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.resolvedBy != null && item.resolvedBy!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'تم الحل بواسطة: ${item.resolvedBy}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF22C55E).withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Add Member Button ────────────────────────────────────────────────────────

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primarySoft],
          ),
        ),
        child: TextButton.icon(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
          label: const Text(
            'إضافة عضو جديد',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  final CommunityMember member;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    member.name,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.status,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      color: member.statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    required this.onNotificationTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF121A5C) : AppColors.primarySoft;
    final textColor = isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: headerBg,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(Icons.arrow_forward_ios, color: textColor, size: 22),
            ),
          ),
          Positioned(
            right: 16,
            top: 52,
            child: GestureDetector(
              onTap: onNotificationTap,
              child: Icon(Icons.notifications_none, color: textColor, size: 24),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
