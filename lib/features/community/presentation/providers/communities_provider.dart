import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../../core/realtime/signalr_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/community_remote_data_source.dart';

// ─── Domain models ────────────────────────────────────────────────────────────

/// Simple UI-level member model used by Community cards.
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

class Community {
  const Community({
    required this.id,
    required this.title,
    required this.membersPreview,
    required this.iconPath,
    required this.members,
    this.memberCount = 0,
    this.description,
    this.inviteCode,
  });

  final String id;
  final String title;
  final String membersPreview;
  final String iconPath;
  final List<CommunityMember> members;
  final int memberCount;
  final String? description;
  final String? inviteCode;
}

// ─── State ────────────────────────────────────────────────────────────────────

class CommunitiesState {
  const CommunitiesState({
    required this.communities,
    required this.searchQuery,
    this.activeSosCounts = const {},
    this.nearbyCommunities = const [],
    this.isLoading = false,
    this.isJoining = false,
    this.error,
    this.joinResult,
    this.showLocationBanner = false,
    this.locationBannerCommunityId,
  });

  final List<Community> communities;
  final String searchQuery;
  final Map<String, int> activeSosCounts;
  final List<NearbyCommunityDto> nearbyCommunities;
  final bool isLoading;
  final bool isJoining;
  final String? error;
  final CommunityJoinResultDto? joinResult;
  final bool showLocationBanner;
  final String? locationBannerCommunityId;

  CommunitiesState copyWith({
    List<Community>? communities,
    String? searchQuery,
    Map<String, int>? activeSosCounts,
    List<NearbyCommunityDto>? nearbyCommunities,
    bool? isLoading,
    bool? isJoining,
    String? error,
    bool clearError = false,
    CommunityJoinResultDto? joinResult,
    bool? showLocationBanner,
    String? locationBannerCommunityId,
  }) {
    return CommunitiesState(
      communities: communities ?? this.communities,
      searchQuery: searchQuery ?? this.searchQuery,
      activeSosCounts: activeSosCounts ?? this.activeSosCounts,
      nearbyCommunities: nearbyCommunities ?? this.nearbyCommunities,
      isLoading: isLoading ?? this.isLoading,
      isJoining: isJoining ?? this.isJoining,
      error: clearError ? null : (error ?? this.error),
      joinResult: joinResult ?? this.joinResult,
      showLocationBanner: showLocationBanner ?? this.showLocationBanner,
      locationBannerCommunityId:
          locationBannerCommunityId ?? this.locationBannerCommunityId,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CommunitiesNotifier extends StateNotifier<CommunitiesState> {
  CommunitiesNotifier(this._remoteDataSource, this._ref)
      : super(const CommunitiesState(communities: [], searchQuery: '')) {
    _loadFromApi();
    _wireSignalR();
  }

  final CommunityRemoteDataSource _remoteDataSource;
  final Ref _ref;

  // ── SignalR ───────────────────────────────────────────────────────────────

  void _wireSignalR() {
    final manager = _ref.read(signalRManagerProvider);
    manager.onSOSTriggered = (alert) {
      if (!mounted) return;
      final communityId = alert['communityId']?.toString() ?? '';
      if (communityId.isEmpty) return;
      final counts = Map<String, int>.from(state.activeSosCounts);
      counts[communityId] = (counts[communityId] ?? 0) + 1;
      state = state.copyWith(activeSosCounts: counts);
    };
    manager.onSOSResolved = (sosId, _) => _decrementSosByCommunity();
    manager.onSOSCancelled = (sosId, _) => _decrementSosByCommunity();
  }

  void _decrementSosByCommunity() {
    if (!mounted) return;
    final counts = Map<String, int>.from(state.activeSosCounts);
    for (final key in counts.keys.toList()) {
      if ((counts[key] ?? 0) > 0) {
        counts[key] = counts[key]! - 1;
        break;
      }
    }
    state = state.copyWith(activeSosCounts: counts);
  }

  void incrementSosCount(String communityId) {
    if (!mounted) return;
    final counts = Map<String, int>.from(state.activeSosCounts);
    counts[communityId] = (counts[communityId] ?? 0) + 1;
    state = state.copyWith(activeSosCounts: counts);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void setSearchQuery(String value) =>
      state = state.copyWith(searchQuery: value.trim());

  /// Creates a community — returns the full response (including inviteCode).
  Future<CreateCommunityResponseDto?> createCommunity({
    required String name,
    String? description,
    int communityType = 0,
    int? coverageRadiusMeters,
  }) async {
    try {
      final result = await _remoteDataSource.createCommunity(
        name: name,
        description: description,
        communityType: communityType,
        coverageRadiusMeters: coverageRadiusMeters,
      );
      final showBanner = result.isLocationPending;
      state = state.copyWith(
        showLocationBanner: showBanner,
        locationBannerCommunityId: showBanner ? result.id : null,
      );
      await _loadFromApi();
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Joins a community via 6-char invite code.
  Future<CommunityJoinResultDto?> joinByInviteCode(String code) async {
    state = state.copyWith(isJoining: true, clearError: true);
    try {
      final result = await _remoteDataSource.joinByInviteCode(code);
      final showBanner = result.isLocationPending;
      state = state.copyWith(
        isJoining: false,
        joinResult: result,
        showLocationBanner: showBanner,
        locationBannerCommunityId: showBanner ? result.communityId : null,
      );
      await _loadFromApi();
      return result;
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
      return null;
    }
  }

  void showLocationPendingBanner({required String communityId}) {
    state = state.copyWith(
      showLocationBanner: true,
      locationBannerCommunityId: communityId,
    );
  }

  void dismissLocationBanner() {
    state = state.copyWith(showLocationBanner: false);
  }

  void onLocationShared() {
    state = state.copyWith(showLocationBanner: false);
    _loadFromApi();
  }

  /// Regenerates the invite code for a community (admin only).
  Future<RegenerateCodeResultDto?> regenerateCode(String communityId) async {
    try {
      return await _remoteDataSource.regenerateCode(communityId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Revokes the invite code (admin only).
  Future<bool> revokeCode(String communityId) async {
    try {
      await _remoteDataSource.revokeCode(communityId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Fetches nearby Neighborhood communities.
  Future<void> loadNearbyCommunities({
    required double lat,
    required double lng,
    double radiusKm = 2.0,
  }) async {
    try {
      final nearby = await _remoteDataSource.fetchNearbyCommunities(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      if (mounted) state = state.copyWith(nearbyCommunities: nearby);
    } catch (_) {}
  }

  Future<void> addMemberByEmail({
    required String communityId,
    required String email,
  }) async {
    await _remoteDataSource.addMemberByEmail(
      communityId: communityId,
      email: email,
    );
    await _loadFromApi();
  }

  Future<void> leaveCommunity(String communityId) async {
    await _remoteDataSource.leaveCommunity(communityId);
    await _loadFromApi();
  }

  Future<void> refresh() => _loadFromApi();

  // ── API load ──────────────────────────────────────────────────────────────

  Future<void> _loadFromApi() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final communities = await _remoteDataSource.fetchAllCommunities();
      debugPrint('[Communities] fetched ${communities.length} communities');

      if (!mounted) return;

      final mapped = <Community>[];
      for (final item in communities) {
        List<CommunityMemberApiModel> members = [];
        try {
          final detail = await _remoteDataSource.fetchCommunityById(item.id);
          members = detail?.members ?? [];
        } catch (e) {
          debugPrint('[Communities] detail fetch failed for ${item.id}: $e');
          try {
            members = await _remoteDataSource.fetchCommunityMembers(item.id);
          } catch (_) {}
        }
        if (!mounted) return;

        mapped.add(
          Community(
            id: item.id,
            title: item.name,
            description: item.description,
            inviteCode: item.inviteCode,
            membersPreview: _buildMembersPreview(members),
            iconPath: 'assets/images/family_comm.png',
            memberCount: members.length,
            members: members
                .map(
                  (m) => CommunityMember(
                    name: m.displayName?.trim().isNotEmpty == true
                        ? m.displayName!
                        : m.email,
                    status: m.memberStatus == MemberStatus.locationPending
                        ? 'يتطلب الموقع'
                        : 'عضو',
                    statusColor: m.memberStatus == MemberStatus.locationPending
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF2E8B57),
                  ),
                )
                .toList(),
          ),
        );
      }

      if (!mounted) return;
      state = state.copyWith(communities: mapped, isLoading: false);
    } catch (e, st) {
      debugPrint('[Communities] _loadFromApi error: $e\n$st');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _buildMembersPreview(List<CommunityMemberApiModel> members) {
    if (members.isEmpty) return '';
    return members
        .map((m) => m.displayName ?? m.email)
        .where((n) => n.trim().isNotEmpty)
        .take(3)
        .join(' , ');
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return CommunityRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

final communitiesProvider =
    StateNotifierProvider<CommunitiesNotifier, CommunitiesState>((ref) {
  return CommunitiesNotifier(
    ref.watch(communityRemoteDataSourceProvider),
    ref,
  );
});

final filteredCommunitiesProvider = Provider<List<Community>>((ref) {
  final state = ref.watch(communitiesProvider);
  final query = state.searchQuery;
  if (query.isEmpty) return state.communities;
  return state.communities
      .where((c) => c.title.contains(query))
      .toList();
});
