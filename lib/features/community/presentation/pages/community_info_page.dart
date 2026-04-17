import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import 'add_member_page.dart';
import 'member_details_page.dart';
import 'community_notification_page.dart';

class CommunityMember {
  const CommunityMember({
    required this.name,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String status;
  final Color statusColor;
}

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
    final pageBackground = isDark
        ? const Color(0xFF060C3A)
        : AppColors.backgroundLight;
    final sectionTitleColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 248,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFF3F6F9)
                            : const Color(0x66060C3A),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildCommunityMap(
                        liveState: liveState,
                        users: users,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'دائرتي',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: sectionTitleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MemberCard(
                        member: member,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MemberDetailsPage(
                                member: member,
                                lastLocation: 'وسط البلد',
                                lastSeenText: 'منذ دقيقتين',
                                activities: const [
                                  'تحديث الموقع',
                                  'دخول منطقة آمنة',
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary, AppColors.primarySoft],
                          ),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddMemberPage(),
                              ),
                            );
                          },
                          child: Text(
                            'أضف عضو جديد',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFF3F6F9)
                                  : AppColors.backgroundLight,
                            ),
                          ),
                        ),
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
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    )
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
            ),
          )
          .toSet();

      return MapScreen(
        initialTarget: users.first.latLng,
        initialZoom: 14,
        myLocationEnabled:
            liveState.accessStatus == LocationAccessStatus.granted,
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
                  if (liveState.accessStatus ==
                      LocationAccessStatus.serviceDisabled) {
                    ref
                        .read(communityLiveLocationProvider.notifier)
                        .openDeviceLocationSettings();
                    return;
                  }

                  if (liveState.accessStatus ==
                      LocationAccessStatus.permanentlyDenied) {
                    ref
                        .read(communityLiveLocationProvider.notifier)
                        .openPermissionSettings();
                    return;
                  }

                  ref
                      .read(communityLiveLocationProvider.notifier)
                      .startTracking(
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
}

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
    final headerBackground = isDark
        ? const Color(0xFF121A5C)
        : AppColors.primarySoft;
    final headerTextColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      height: 100,
      color: headerBackground,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(
                Icons.arrow_forward_ios,
                color: headerTextColor,
                size: 24,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 52,
            child: GestureDetector(
              onTap: onNotificationTap,
              child: Icon(
                Icons.notifications_none,
                color: headerTextColor,
                size: 24,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: headerTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

  final CommunityMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? const Color(0xFF060C3A) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFFF3F6F9)
        : const Color(0x66060C3A);
    final memberNameColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/user_chatbot.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
                          color: memberNameColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        member.status,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: member.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
