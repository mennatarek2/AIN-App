import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../location/data/location_service.dart';
import '../../../location/presentation/providers/location_providers.dart';
import '../../../location/presentation/widgets/map_screen.dart';
import '../../data/community_remote_data_source.dart';
import '../../models/join_request.dart';
import '../../models/member_detail.dart';
import '../../models/community_detail.dart';
import '../../utils/community_helpers.dart';
import '../../utils/community_permissions.dart';
import '../providers/communities_provider.dart';
import '../widgets/community_dialogs.dart';
import '../widgets/community_invite_code_card.dart';
import '../widgets/community_join_requests_tab.dart';
import 'add_member_page.dart';
import 'community_notification_page.dart';
import 'edit_community_page.dart';
import 'member_details_page.dart';
import '../../../home/presentation/pages/your_location_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

enum _CommunityTab { info, members, requests, map }

class CommunityInfoPage extends ConsumerStatefulWidget {
  const CommunityInfoPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.members,
    this.inviteCode,
  });

  final String communityId;
  final String communityName;
  final List<CommunityMember> members;
  final String? inviteCode;

  @override
  ConsumerState<CommunityInfoPage> createState() => _CommunityInfoPageState();
}

class _CommunityInfoPageState extends ConsumerState<CommunityInfoPage> {
  bool _isLeaving = false;
  bool _isDeleting = false;
  _CommunityTab _selectedTab = _CommunityTab.info;

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
    final liveState = ref.watch(communityLiveLocationProvider);
    final users = ref.watch(communityUsersProvider(widget.communityId));
    final sosHistoryAsync = ref.watch(
      communitySosHistoryProvider(widget.communityId),
    );
    final commState = ref.watch(communitiesProvider);
    final membersAsync = ref.watch(
      communityMembersDetailProvider(widget.communityId),
    );
    final detailAsync = ref.watch(communityDetailProvider(widget.communityId));
    final pendingAsync = ref.watch(
      pendingJoinRequestsProvider(widget.communityId),
    );
    final currentUser = ref.watch(currentUserProvider);
    // profileProvider returns the profile fetched from /api/Profile/my-profile,
    // which always carries the real database UUID in its `id` field.
    // We prefer it over currentUser.id because currentUser.id can fall back
    // to the user's email address when the login response omits an `id` field,
    // causing the membership lookup to fail and hiding all admin-only UI.
    final profileUser = ref.watch(profileProvider);
    final effectiveUserId =
        (profileUser?.id.isNotEmpty == true ? profileUser!.id : null) ??
        currentUser?.id;
    final activeSosCount = commState.activeSosCounts[widget.communityId] ?? 0;
    final memberCount =
        detailAsync.valueOrNull?.totalMemberCount ??
        membersAsync.valueOrNull?.where((member) => member.isApproved).length ??
        widget.members.length;
    final myMemberRecord = effectiveUserId == null
        ? null
        : myMembership(membersAsync.valueOrNull ?? const [], effectiveUserId);
    final myRole = myMemberRecord?.role;
    final communityType = detailAsync.valueOrNull?.communityType;
    final showRequestsTab =
        communityType == CommunityType.neighborhood &&
        CommunityPermissions.canViewJoinRequests(myRole);
    final pendingCount =
        pendingAsync.valueOrNull
            ?.where((request) => request.status == JoinStatus.pending)
            .length ??
        0;
    final displayName = detailAsync.valueOrNull?.name ?? widget.communityName;
    final isOwner = myRole == CommunityRole.owner;
    final isMember = myMemberRecord != null;

    if (!showRequestsTab && _selectedTab == _CommunityTab.requests) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedTab = _CommunityTab.info);
      });
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: displayName,
            subtitle: '$memberCount عضو',
            onBack: () => Navigator.of(context).pop(),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommunityNotificationPage(
                        communityId: widget.communityId,
                        communityName: widget.communityName,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: context.semantic.textOnPrimary,
                ),
                tooltip: 'التنبيهات',
              ),
            ],
          ),
          if (activeSosCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: _ActiveSOSBanner(count: activeSosCount),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
            ),
            child: _TabSelector(
              selected: _selectedTab,
              memberCount: memberCount,
              showRequestsTab: showRequestsTab,
              pendingCount: pendingCount,
              onChanged: (tab) => setState(() => _selectedTab = tab),
            ),
          ),
          Expanded(
            child: switch (_selectedTab) {
              _CommunityTab.map => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                child: _MapSection(
                  liveState: liveState,
                  users: users,
                  communityId: widget.communityId,
                  expanded: true,
                  onRetry: () {
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
                ),
              ),
              _CommunityTab.requests => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxl,
                ),
                child: CommunityJoinRequestsTab(
                  communityId: widget.communityId,
                ),
              ),
              _ => RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(communitiesProvider.notifier)
                      .refreshCommunityData(widget.communityId);
                  await Future.wait([
                    ref.refresh(
                      communityDetailProvider(widget.communityId).future,
                    ),
                    ref.refresh(
                      communityMembersDetailProvider(widget.communityId).future,
                    ),
                    ref.refresh(
                      communitySosHistoryProvider(widget.communityId).future,
                    ),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxl,
                  ),
                  child: switch (_selectedTab) {
                    _CommunityTab.info => _InfoSection(
                      communityId: widget.communityId,
                      detailAsync: detailAsync,
                      inviteCode:
                          detailAsync.valueOrNull?.inviteCode ??
                          widget.inviteCode,
                      myRole: myRole,
                      myMembership: myMemberRecord,
                      canManageCodes: CommunityPermissions.canManageCodes(
                        myRole,
                      ),
                      canEdit: CommunityPermissions.canEditCommunity(myRole),
                      isOwner: isOwner,
                      isMember: isMember,
                      sosHistoryAsync: sosHistoryAsync,
                      isLeaving: _isLeaving,
                      isDeleting: _isDeleting,
                      onLeave: _showLeaveDialog,
                      onDelete: () => _confirmDeleteCommunity(context, ref),
                    ),
                    _CommunityTab.members => _MembersSection(
                      membersAsync: membersAsync,
                      communityId: widget.communityId,
                      currentUserId: effectiveUserId,
                      myRole: myRole,
                      includePendingPanel: !showRequestsTab,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaveDialog() async {
    // Guard: prevent opening a second dialog while already leaving.
    if (_isLeaving) return;

    // Determine current role so we can warn the owner.
    final membersSnap = ref.read(
      communityMembersDetailProvider(widget.communityId),
    );
    final profileUser = ref.read(profileProvider);
    final currentUserId =
        (profileUser?.id.isNotEmpty == true ? profileUser!.id : null) ??
        ref.read(currentUserProvider)?.id;
    final myRole = currentUserId == null
        ? null
        : myMembership(membersSnap.valueOrNull ?? const [], currentUserId)
            ?.role;
    final userIsOwner = myRole == CommunityRole.owner;

    final confirmed = await CommunityDialogs.confirmLeave(
      context,
      communityName: widget.communityName,
      isOwner: userIsOwner,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isLeaving = true);
    final error = await ref
        .read(communitiesProvider.notifier)
        .leaveCommunity(widget.communityId);
    if (!mounted) return;
    setState(() => _isLeaving = false);

    if (error != null) {
      // 401 — token expired: log out and send to login.
      if (error.contains('401') ||
          error.toLowerCase().contains('unauthorized') ||
          error.toLowerCase().contains('unauthenticated')) {
        await ref.read(authNotifierProvider.notifier).logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
        return;
      }
      // All other errors — inline red SnackBar, sheet stays open.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, textDirection: TextDirection.rtl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteCommunity(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await CommunityDialogs.confirmDeleteCommunity(context);

    if (!confirmed || !mounted) return;
    setState(() => _isDeleting = true);
    final error = await ref
        .read(communitiesProvider.notifier)
        .deleteCommunity(widget.communityId);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف المجتمع', textDirection: TextDirection.rtl),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.selected,
    required this.memberCount,
    required this.showRequestsTab,
    required this.pendingCount,
    required this.onChanged,
  });

  final _CommunityTab selected;
  final int memberCount;
  final bool showRequestsTab;
  final int pendingCount;
  final ValueChanged<_CommunityTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      Expanded(
        child: _TabPill(
          label: 'معلومات',
          icon: Icons.info_outline_rounded,
          isSelected: selected == _CommunityTab.info,
          onTap: () => onChanged(_CommunityTab.info),
        ),
      ),
      if (showRequestsTab)
        Expanded(
          child: _TabPill(
            label: pendingCount > 0
                ? 'طلبات ($pendingCount)'
                : 'طلبات الانضمام',
            icon: Icons.person_add_alt_1_rounded,
            isSelected: selected == _CommunityTab.requests,
            onTap: () => onChanged(_CommunityTab.requests),
          ),
        ),
      Expanded(
        child: _TabPill(
          label: 'الأعضاء ($memberCount)',
          icon: Icons.people_rounded,
          isSelected: selected == _CommunityTab.members,
          onTap: () => onChanged(_CommunityTab.members),
        ),
      ),
      Expanded(
        child: _TabPill(
          label: 'الخريطة',
          icon: Icons.map_rounded,
          isSelected: selected == _CommunityTab.map,
          onTap: () => onChanged(_CommunityTab.map),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Row(textDirection: TextDirection.rtl, children: tabs),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? context.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: isSelected ? context.cardShadows : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? context.semantic.textOnPrimary
                      : context.semantic.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.2,
                    color: isSelected
                        ? context.semantic.textOnPrimary
                        : context.semantic.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.liveState,
    required this.users,
    required this.communityId,
    required this.onRetry,
    this.expanded = false,
  });

  final CommunityLiveLocationState liveState;
  final List<LiveUserLocation> users;
  final String communityId;
  final VoidCallback onRetry;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: _buildCommunityMap(context),
        ),
      );
    }

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(height: 320, child: _buildCommunityMap(context)),
      ),
    );
  }

  Widget _buildCommunityMap(BuildContext context) {
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
      color: context.semantic.surfaceInput,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 40,
                color: context.semantic.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                liveState.accessStatus == LocationAccessStatus.serviceDisabled
                    ? 'يرجى تشغيل GPS لعرض خريطة المجتمع'
                    : (liveState.errorMessage ?? 'لا توجد بيانات مواقع حالياً'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersSection extends ConsumerWidget {
  const _MembersSection({
    required this.membersAsync,
    required this.communityId,
    required this.currentUserId,
    required this.myRole,
    this.includePendingPanel = true,
  });

  final AsyncValue<List<MemberDetailDto>> membersAsync;
  final String communityId;
  final String? currentUserId;
  final CommunityRole? myRole;
  final bool includePendingPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return membersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => AppSurfaceCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'تعذّر تحميل الأعضاء',
              textDirection: TextDirection.rtl,
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
          ),
        ),
      ),
      data: (members) {
        final canManage = CommunityPermissions.canManageMembers(myRole);
        final canChange = CommunityPermissions.canChangeRoles(myRole);
        final isAdmin = myRole == CommunityRole.admin;
        final approvedMembers = members
            .where((member) => member.isApproved)
            .toList();
        final uiMembers = approvedMembers
            .map(
              (member) => CommunityMember(
                userId: member.userId,
                name: member.userName,
                role: member.role,
                joinStatus: member.joinStatus,
                status: memberStatusLabelAr(member.memberStatus),
                statusColor: memberStatusColor(member.memberStatus),
              ),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (includePendingPanel && canManage)
              _PendingJoinRequestsPanel(communityId: communityId),
            if (includePendingPanel && canManage)
              const SizedBox(height: AppSpacing.md),
            if (uiMembers.isNotEmpty) ...[
              AppSurfaceCard(child: _MembersAvatarRow(members: uiMembers)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (uiMembers.isEmpty)
              AppSurfaceCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'لم يتم العثور على أعضاء',
                      textDirection: TextDirection.rtl,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...approvedMembers.map((detail) {
                final isSelf = detail.userId == currentUserId;
                final isOwnerTarget = detail.role == CommunityRole.owner;
                final canKick =
                    !isSelf &&
                    ((canChange && !isOwnerTarget) ||
                        (isAdmin &&
                            detail.role.index < CommunityRole.admin.index));
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MemberCard(
                    member: detail,
                    showAdminActions:
                        canKick || (canChange && !isSelf && !isOwnerTarget),
                    onKick: canKick
                        ? () => CommunityMemberActions.kick(
                            context: context,
                            ref: ref,
                            communityId: communityId,
                            userId: detail.userId,
                            userName: detail.userName,
                          )
                        : null,
                    onChangeRole: canChange && !isSelf && !isOwnerTarget
                        ? () => CommunityMemberActions.changeRole(
                            context: context,
                            ref: ref,
                            communityId: communityId,
                            userId: detail.userId,
                            userName: detail.userName,
                            currentRole: detail.role,
                          )
                        : null,
                    onTransferOwnership:
                        canChange &&
                            !isSelf &&
                            detail.isApproved &&
                            !isOwnerTarget
                        ? () => CommunityMemberActions.transferOwnership(
                            context: context,
                            ref: ref,
                            communityId: communityId,
                            userId: detail.userId,
                            userName: detail.userName,
                          )
                        : null,
                    onTap: () async {
                      final refreshed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => MemberDetailsPage(
                            memberDetail: detail,
                            communityId: communityId,
                            currentUserId: currentUserId ?? '',
                            myRole: myRole,
                          ),
                        ),
                      );
                      if (refreshed == true) {
                        ref.invalidate(
                          communityMembersDetailProvider(communityId),
                        );
                        ref.invalidate(communityDetailProvider(communityId));
                      }
                    },
                  ),
                );
              }),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: context.primaryGradient,
                  ),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddMemberPage(communityId: communityId),
                      ),
                    ),
                    icon: Icon(
                      Icons.person_add_rounded,
                      color: context.semantic.textOnPrimary,
                      size: 18,
                    ),
                    label: Text(
                      'إضافة عضو جديد',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: context.semantic.textOnPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PendingJoinRequestsPanel extends ConsumerStatefulWidget {
  const _PendingJoinRequestsPanel({required this.communityId});

  final String communityId;

  @override
  ConsumerState<_PendingJoinRequestsPanel> createState() =>
      _PendingJoinRequestsPanelState();
}

class _PendingJoinRequestsPanelState
    extends ConsumerState<_PendingJoinRequestsPanel> {
  String? _processingUserId;

  String _formatRequestDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _approve(String userId) async {
    setState(() => _processingUserId = userId);
    final error = await ref
        .read(communitiesProvider.notifier)
        .approveJoinRequest(widget.communityId, userId);
    if (mounted) setState(() => _processingUserId = null);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم قبول طلب الانضمام', textDirection: TextDirection.rtl),
      ),
    );
  }

  Future<void> _reject(String userId, String userName) async {
    if (!await CommunityDialogs.confirmRejectJoinRequest(
      context,
      userName: userName,
    )) {
      return;
    }

    setState(() => _processingUserId = userId);
    final error = await ref
        .read(communitiesProvider.notifier)
        .rejectJoinRequest(widget.communityId, userId);
    if (mounted) setState(() => _processingUserId = null);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفض طلب الانضمام', textDirection: TextDirection.rtl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(
      pendingJoinRequestsProvider(widget.communityId),
    );

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => AppSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'تعذّر تحميل طلبات الانضمام',
            textDirection: TextDirection.rtl,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.error,
            ),
          ),
        ),
      ),
      data: (requests) {
        final pending = requests
            .where((r) => r.status == JoinStatus.pending)
            .toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: pending.map((request) {
            final isProcessing = _processingUserId == request.userId;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _JoinRequestAvatar(request: request),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.userName,
                                textDirection: TextDirection.rtl,
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'طُلب ${_formatRequestDate(request.requestedAt)}',
                                textDirection: TextDirection.rtl,
                                style: context.text.labelSmall?.copyWith(
                                  color: context.semantic.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isProcessing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _reject(request.userId, request.userName),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.semantic.error,
                                side: BorderSide(
                                  color: context.semantic.error.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approve(request.userId),
                              child: const Text('قبول'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _JoinRequestAvatar extends StatelessWidget {
  const _JoinRequestAvatar({required this.request});

  final JoinRequestDto request;

  @override
  Widget build(BuildContext context) {
    final photoUrl = request.profilePhotoUrl?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedAppImage(
          imagePath: photoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: _JoinRequestAvatarFallback(userName: request.userName),
        ),
      );
    }
    return _JoinRequestAvatarFallback(userName: request.userName);
  }
}

class _JoinRequestAvatarFallback extends StatelessWidget {
  const _JoinRequestAvatarFallback({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: context.colors.primary,
      child: Text(
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          color: context.semantic.textOnPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoSection extends ConsumerWidget {
  const _InfoSection({
    required this.communityId,
    required this.detailAsync,
    required this.inviteCode,
    required this.myRole,
    required this.myMembership,
    required this.canManageCodes,
    required this.canEdit,
    required this.isOwner,
    required this.isMember,
    required this.sosHistoryAsync,
    required this.isLeaving,
    required this.isDeleting,
    required this.onLeave,
    required this.onDelete,
  });

  final String communityId;
  final AsyncValue<CommunityDetail?> detailAsync;
  final String? inviteCode;
  final CommunityRole? myRole;
  final MemberDetailDto? myMembership;
  final bool canManageCodes;
  final bool canEdit;
  final bool isOwner;
  final bool isMember;
  final AsyncValue<List<SosHistoryItem>> sosHistoryAsync;
  final bool isLeaving;
  final bool isDeleting;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLocationWarning =
        myMembership?.memberStatus == MemberStatus.locationPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLocationWarning) ...[
          _LocationPendingDetailBanner(
            onSetLocation: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const YourLocationPage()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        detailAsync.when(
          loading: () => const AppSurfaceCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => AppSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'تعذّر تحميل بيانات المجتمع',
                textDirection: TextDirection.rtl,
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.textMuted,
                ),
              ),
            ),
          ),
          data: (detail) {
            if (detail == null) {
              return AppSurfaceCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'المجتمع غير موجود',
                    textDirection: TextDirection.rtl,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        detail.name,
                        textDirection: TextDirection.rtl,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (detail.description?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          detail.description!,
                          textDirection: TextDirection.rtl,
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        textDirection: TextDirection.rtl,
                        children: [
                          _InfoTag(label: detail.communityType.labelAr),
                          if (detail.coverageRadiusMeters != null)
                            _InfoTag(
                              label: 'نطاق ${detail.coverageRadiusMeters} م',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'أنشأها ${detail.createdByName}',
                        textDirection: TextDirection.rtl,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SosReadinessBar(percent: detail.sosReadinessPercent),
                const SizedBox(height: AppSpacing.md),
                _MemberStatsRow(
                  active: detail.activeMemberCount,
                  pending: detail.locationPendingCount,
                  inactive: detail.inactiveMemberCount,
                  total: detail.totalMemberCount,
                ),
                if (canEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditCommunityPage(
                            communityId: communityId,
                            initialDetail: detail,
                          ),
                        ),
                      );
                      if (updated == true) {
                        ref.invalidate(communityDetailProvider(communityId));
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل المجتمع'),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CommunityInviteCodeCard(
          communityId: communityId,
          inviteCode: inviteCode,
          canManageCodes: canManageCodes,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppSectionHeader(
          title: 'سجل حوادث سابقة',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        sosHistoryAsync.when(
          loading: () => const AppSurfaceCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (e, _) => AppSurfaceCard(
            child: Text(
              'تعذّر تحميل السجل',
              textDirection: TextDirection.rtl,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
          ),
          data: (history) => history.isEmpty
              ? AppSurfaceCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'لا توجد حوادث سابقة',
                        textDirection: TextDirection.rtl,
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: history
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _PastSOSCard(item: item),
                        ),
                      )
                      .toList(),
                ),
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: isDeleting ? null : onDelete,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDeleting
                    ? context.semantic.borderStrong
                    : context.semantic.error,
              ),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: isDeleting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.semantic.error,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: context.semantic.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'حذف المجتمع',
                        style: TextStyle(
                          color: context.semantic.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ] else if (isMember) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: isLeaving ? null : onLeave,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isLeaving
                    ? context.semantic.borderStrong
                    : context.semantic.error,
              ),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: isLeaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.semantic.error,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.exit_to_app_rounded,
                        color: context.semantic.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مغادرة المجتمع',
                        style: TextStyle(
                          color: context.semantic.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

class _LocationPendingDetailBanner extends StatelessWidget {
  const _LocationPendingDetailBanner({required this.onSetLocation});

  final VoidCallback onSetLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.semantic.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semantic.warning),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.warning_amber_rounded, color: context.semantic.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '⚠️ موقعك غير محدد. حدّثه من الملف الشخصي لتفعيل SOS.',
              textDirection: TextDirection.rtl,
              style: context.text.bodySmall,
            ),
          ),
          TextButton(onPressed: onSetLocation, child: const Text('تحديد')),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: context.text.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.semantic.textMuted,
        ),
      ),
    );
  }
}

class _SosReadinessBar extends StatelessWidget {
  const _SosReadinessBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 70
        ? context.semantic.success
        : percent >= 40
        ? context.semantic.warning
        : context.semantic.error;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOS جاهزية',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percent%',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 10,
              backgroundColor: context.semantic.borderSubtle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatsRow extends StatelessWidget {
  const _MemberStatsRow({
    required this.active,
    required this.pending,
    required this.inactive,
    required this.total,
  });

  final int active;
  final int pending;
  final int inactive;
  final int total;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        textDirection: TextDirection.rtl,
        children: [
          _StatPill(
            label: 'نشط',
            value: active,
            color: context.semantic.success,
          ),
          _StatPill(
            label: 'بانتظار الموقع',
            value: pending,
            color: context.semantic.warning,
          ),
          _StatPill(
            label: 'غير نشط',
            value: inactive,
            color: context.semantic.error,
          ),
          _StatPill(
            label: 'الإجمالي',
            value: total,
            color: context.colors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.surfaceInput,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$value $label',
            textDirection: TextDirection.rtl,
            style: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final sosColor = context.semantic.sos;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final borderColor = Color.lerp(
          sosColor,
          sosColor.withValues(alpha: 0.5),
          _ctrl.value,
        )!;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: sosColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.crisis_alert_rounded, color: sosColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'يوجد ${widget.count > 1 ? '${widget.count} نداءات طوارئ' : 'نداء طوارئ'} نشط',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: sosColor,
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

class _MembersAvatarRow extends StatelessWidget {
  const _MembersAvatarRow({required this.members});

  final List<CommunityMember> members;

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    const maxVisible = 6;
    final visible = members.take(maxVisible).toList();
    final extra = members.length - maxVisible;

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: Stack(
              children: [
                ...visible.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return Positioned(
                    right: i * 30.0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _avatarColors[i % 5],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.semantic.surfaceContainer,
                          width: 2.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: context.semantic.textOnPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
                if (extra > 0)
                  Positioned(
                    right: maxVisible * 30.0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.semantic.borderStrong,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.semantic.surfaceContainer,
                          width: 2.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$extra',
                        style: TextStyle(
                          color: context.semantic.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          '${members.length} عضو',
          textDirection: TextDirection.rtl,
          style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PastSOSCard extends StatelessWidget {
  const _PastSOSCard({required this.item});

  final SosHistoryItem item;

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
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: _severityColor.withValues(alpha: 0.4),
                  ),
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
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
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
                style: context.text.labelSmall?.copyWith(
                  color: context.semantic.textMuted,
                ),
              ),
            ],
          ),
          if (item.message != null && item.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.message!,
              textDirection: TextDirection.rtl,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.resolvedBy != null && item.resolvedBy!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'تم الحل بواسطة: ${item.resolvedBy}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 12,
                color: context.semantic.success.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    this.showAdminActions = false,
    this.onKick,
    this.onChangeRole,
    this.onTransferOwnership,
  });

  final MemberDetailDto member;
  final VoidCallback onTap;
  final bool showAdminActions;
  final VoidCallback? onKick;
  final VoidCallback? onChangeRole;
  final VoidCallback? onTransferOwnership;

  bool get _hasAdminMenu =>
      showAdminActions &&
      (onKick != null || onChangeRole != null || onTransferOwnership != null);

  @override
  Widget build(BuildContext context) {
    final roleColor = roleBadgeColor(member.role);
    final statusColor = memberStatusColor(member.memberStatus);
    final statusLabel = memberStatusLabelAr(member.memberStatus);

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Text(
              member.userName.isNotEmpty
                  ? member.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  textDirection: TextDirection.rtl,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusLabel,
                  textDirection: TextDirection.rtl,
                  style: context.text.bodySmall?.copyWith(color: statusColor),
                ),
                Text(
                  formatJoinedDateAr(member.joinedAt),
                  textDirection: TextDirection.rtl,
                  style: context.text.labelSmall?.copyWith(
                    color: context.semantic.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              roleBadgeLabelAr(member.role),
              style: context.text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: roleColor,
              ),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            side: BorderSide(color: roleColor.withValues(alpha: 0.35)),
          ),
          if (_hasAdminMenu)
            IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.semantic.textMuted,
                size: 20,
              ),
              tooltip: 'إجراءات العضو',
              onPressed: () => CommunityDialogs.showMemberActionsSheet(
                context,
                userName: member.userName,
                onChangeRole: onChangeRole,
                onKick: onKick,
                onTransferOwnership: onTransferOwnership,
              ),
            ),
          Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: context.semantic.textMuted,
          ),
        ],
      ),
    );
  }
}
