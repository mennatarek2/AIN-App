import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_providers.dart';
import '../../../../core/realtime/signalr_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state_simple.dart';
import '../../data/community_remote_data_source.dart';
import '../../models/community_detail.dart';
import '../../models/community_search_result.dart';
import '../../models/join_request.dart';
import '../../models/member_detail.dart';
import '../../utils/community_helpers.dart';

// ─── Domain models ────────────────────────────────────────────────────────────

/// Simple UI-level member model used by Community cards.
class CommunityMember {
  const CommunityMember({
    required this.name,
    required this.status,
    required this.statusColor,
    this.userId,
    this.role,
    this.joinStatus,
  });

  final String name;
  final String status;
  final Color statusColor;
  final String? userId;
  final CommunityRole? role;
  final JoinStatus? joinStatus;
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
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isJoining = false,
    this.error,
    this.joinErrorCode,
    this.joinResult,
    this.showLocationBanner = false,
    this.locationBannerCommunityId,
  });

  final List<Community> communities;
  final String searchQuery;
  final Map<String, int> activeSosCounts;
  final List<NearbyCommunityDto> nearbyCommunities;
  final List<CommunitySearchResult> searchResults;
  final bool isLoading;
  final bool isSearching;
  final bool isJoining;
  final String? error;
  /// HTTP status code of the last join-by-code error (null if none).
  final int? joinErrorCode;
  final CommunityJoinResultDto? joinResult;
  final bool showLocationBanner;
  final String? locationBannerCommunityId;

  CommunitiesState copyWith({
    List<Community>? communities,
    String? searchQuery,
    Map<String, int>? activeSosCounts,
    List<NearbyCommunityDto>? nearbyCommunities,
    List<CommunitySearchResult>? searchResults,
    bool? isLoading,
    bool? isSearching,
    bool? isJoining,
    String? error,
    bool clearError = false,
    int? joinErrorCode,
    bool clearJoinError = false,
    CommunityJoinResultDto? joinResult,
    bool? showLocationBanner,
    String? locationBannerCommunityId,
  }) {
    return CommunitiesState(
      communities: communities ?? this.communities,
      searchQuery: searchQuery ?? this.searchQuery,
      activeSosCounts: activeSosCounts ?? this.activeSosCounts,
      nearbyCommunities: nearbyCommunities ?? this.nearbyCommunities,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isJoining: isJoining ?? this.isJoining,
      error: clearError ? null : (error ?? this.error),
      joinErrorCode: clearJoinError ? null : (joinErrorCode ?? this.joinErrorCode),
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
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous is AuthAuthenticated;
      final nowAuthenticated = next is AuthAuthenticated;
      if (!wasAuthenticated && nowAuthenticated) {
        _loadFromApi();
      }
    });
    if (_ref.read(authNotifierProvider) is AuthAuthenticated) {
      Future.microtask(_loadFromApi);
    }
  }

  final CommunityRemoteDataSource _remoteDataSource;
  final Ref _ref;
  String? _lastSearchNameQuery;
  int? _lastSearchType;
  final Map<String, List<String>> _sosCommunityIdsByAlert = {};

  // ── SignalR (called from SignalRBridge — do not overwrite manager callbacks) ─

  List<String> _affectedCommunityIdsFromAlert(Map<String, dynamic> alert) {
    final raw = alert['affectedCommunityIds'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .map((item) => item.toString())
          .where((id) => id.isNotEmpty)
          .toList();
    }
    final communityId = alert['communityId']?.toString() ?? '';
    if (communityId.isNotEmpty) return [communityId];
    return const [];
  }

  void handleSosTriggered(Map<String, dynamic> alert) {
    if (!mounted) return;
    final sosId = alert['id']?.toString() ?? '';
    final communityIds = _affectedCommunityIdsFromAlert(alert);
    if (communityIds.isEmpty) return;
    if (sosId.isNotEmpty) {
      _sosCommunityIdsByAlert[sosId] = communityIds;
    }
    final counts = Map<String, int>.from(state.activeSosCounts);
    for (final id in communityIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    state = state.copyWith(activeSosCounts: counts);
  }

  void handleSosEnded(String sosId) {
    if (!mounted) return;
    final communityIds = _sosCommunityIdsByAlert.remove(sosId);
    final counts = Map<String, int>.from(state.activeSosCounts);
    if (communityIds != null && communityIds.isNotEmpty) {
      for (final id in communityIds) {
        if ((counts[id] ?? 0) > 0) {
          counts[id] = counts[id]! - 1;
        }
      }
    } else {
      for (final key in counts.keys.toList()) {
        if ((counts[key] ?? 0) > 0) {
          counts[key] = counts[key]! - 1;
          break;
        }
      }
    }
    state = state.copyWith(activeSosCounts: counts);
  }

  Future<void> joinAllSignalRGroups() async {
    try {
      final manager = _ref.read(signalRManagerProvider);
      if (!manager.isConnected) return;
      for (final community in state.communities) {
        await manager.joinCommunityGroup(community.id);
      }
    } catch (_) {}
  }

  void _invalidateMembers(String communityId) {
    _ref.invalidate(communityMembersDetailProvider(communityId));
  }

  void _invalidatePending(String communityId) {
    _ref.invalidate(pendingJoinRequestsProvider(communityId));
  }

  void _invalidateCommunityDetail(String communityId) {
    _ref.invalidate(communityDetailProvider(communityId));
  }

  void refreshCommunityData(String communityId) {
    _invalidateCommunityDetail(communityId);
    _invalidateMembers(communityId);
    _invalidatePending(communityId);
    _ref.invalidate(communitySosHistoryProvider(communityId));
  }

  Future<void> _refreshLastSearch() async {
    if (_lastSearchNameQuery != null ||
        _lastSearchType != null ||
        state.searchResults.isNotEmpty) {
      await searchCommunities(
        nameQuery: _lastSearchNameQuery,
        type: _lastSearchType,
      );
    }
  }

  // ── §7 cache invalidation ─────────────────────────────────────────────────

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

  /// Joins a neighborhood community via join request (admin approval required).
  Future<CommunityJoinResultDto?> requestToJoin(String communityId) async {
    state = state.copyWith(isJoining: true, clearError: true);
    try {
      final result = await _remoteDataSource.requestToJoin(communityId);
      final showBanner = result.isLocationPending;
      state = state.copyWith(
        isJoining: false,
        joinResult: result,
        showLocationBanner: showBanner,
        locationBannerCommunityId: showBanner ? communityId : null,
      );
      await _loadFromApi();
      await _refreshLastSearch();
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: communityApiUserMessage(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
      return null;
    }
  }

  /// Joins a community via 6-char invite code.
  Future<CommunityJoinResultDto?> joinByInviteCode(String code) async {
    state = state.copyWith(
      isJoining: true,
      clearError: true,
      clearJoinError: true,
    );
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
    } on ApiException catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: communityApiUserMessage(e),
        joinErrorCode: e.statusCode,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isJoining: false,
        error: e.toString(),
        joinErrorCode: 0,
      );
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
    return regenerateInviteCode(communityId);
  }

  /// Revokes the invite code (admin only).
  Future<bool> revokeCode(String communityId) async {
    final error = await revokeInviteCode(communityId);
    return error == null;
  }

  /// Search/discover communities by name or type (PrivateGroup excluded server-side).
  Future<void> searchCommunities({String? nameQuery, int? type}) async {
    _lastSearchNameQuery = nameQuery;
    _lastSearchType = type;
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final results = await _remoteDataSource.searchCommunities(
        nameQuery: nameQuery,
        type: type,
      );
      if (mounted) {
        state = state.copyWith(searchResults: results, isSearching: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSearching: false, error: e.toString());
      }
    }
  }

  void clearSearchResults() {
    state = state.copyWith(searchResults: const []);
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

  Future<String?> addMemberByEmail({
    required String communityId,
    required String email,
  }) async {
    try {
      await _remoteDataSource.addMemberByEmail(
        communityId: communityId,
        email: email,
      );
      _invalidateMembers(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> leaveCommunity(String communityId) async {
    try {
      await _remoteDataSource.leaveCommunity(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCommunity({
    required String communityId,
    required String name,
    String? description,
    required CommunityType type,
    int? coverageRadiusMeters,
  }) async {
    try {
      await _remoteDataSource.updateCommunity(
        communityId: communityId,
        name: name,
        description: description,
        type: type,
        coverageRadiusMeters: coverageRadiusMeters,
      );
      _invalidateCommunityDetail(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCommunity(String communityId) async {
    try {
      await _remoteDataSource.archiveCommunity(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendLocationReminder({
    required String communityId,
    required String memberId,
  }) async {
    try {
      await _remoteDataSource.sendLocationReminder(
        communityId: communityId,
        memberId: memberId,
      );
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<RegenerateCodeResultDto?> regenerateInviteCode(
    String communityId,
  ) async {
    try {
      final result = await _remoteDataSource.regenerateCode(communityId);
      refreshCommunityData(communityId);
      await _loadFromApi();
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(error: communityApiUserMessage(e));
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<String?> revokeInviteCode(String communityId) async {
    try {
      await _remoteDataSource.revokeCode(communityId);
      refreshCommunityData(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> approveJoinRequest(String communityId, String userId) async {
    try {
      await _remoteDataSource.approveRequest(communityId, userId);
      refreshCommunityData(communityId);
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> rejectJoinRequest(String communityId, String userId) async {
    try {
      await _remoteDataSource.rejectRequest(communityId, userId);
      refreshCommunityData(communityId);
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> kickMember(String communityId, String userId) async {
    try {
      await _remoteDataSource.kickMember(communityId, userId);
      refreshCommunityData(communityId);
      return null;
    } on ApiException catch (e) {
      return kickMemberErrorMessageAr(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changeMemberRole(
    String communityId,
    String userId,
    CommunityRole newRole,
  ) async {
    try {
      await _remoteDataSource.changeMemberRole(communityId, userId, newRole);
      refreshCommunityData(communityId);
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> transferOwnership(
    String communityId,
    String newOwnerUserId,
  ) async {
    try {
      await _remoteDataSource.transferOwnership(communityId, newOwnerUserId);
      refreshCommunityData(communityId);
      await _loadFromApi();
      return null;
    } on ApiException catch (e) {
      return communityApiUserMessage(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() => _loadFromApi();

  // ── API load ──────────────────────────────────────────────────────────────

  Future<void> _loadFromApi() async {
    if (!mounted) return;

    final token = await _ref.read(userLocalDataSourceProvider).getCachedToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('[Communities] Skipping load — auth token not available yet');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final communities = await _remoteDataSource.fetchAllCommunities();
      debugPrint('[Communities] fetched ${communities.length} communities');

      if (!mounted) return;

      final mapped = <Community>[];
      for (final item in communities) {
        List<MemberDetailDto> memberDetails = [];
        try {
          memberDetails = await _remoteDataSource.getMembers(item.id);
        } catch (e) {
          debugPrint('[Communities] getMembers failed for ${item.id}: $e');
          try {
            final legacy = await _remoteDataSource.fetchCommunityMembers(
              item.id,
            );
            memberDetails = legacy
                .map(
                  (m) => MemberDetailDto(
                    userId: m.id,
                    userName: m.displayName?.trim().isNotEmpty == true
                        ? m.displayName!
                        : m.email,
                    role: CommunityRole.member,
                    joinStatus: JoinStatus.approved,
                    joinedAt: DateTime.now(),
                  ),
                )
                .toList();
          } catch (_) {}
        }
        if (!mounted) return;

        final approvedMembers = memberDetails
            .where((member) => member.isApproved)
            .toList();

        mapped.add(
          Community(
            id: item.id,
            title: item.name,
            description: item.description,
            inviteCode: item.inviteCode,
            membersPreview: _buildMembersPreviewFromDetails(approvedMembers),
            iconPath: 'assets/images/family_comm.png',
            memberCount: approvedMembers.length,
            members: memberDetails.map(_mapMemberDetail).toList(),
          ),
        );
      }

      if (!mounted) return;
      state = state.copyWith(communities: mapped, isLoading: false);
      await joinAllSignalRGroups();
    } catch (e, st) {
      debugPrint('[Communities] _loadFromApi error: $e\n$st');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  CommunityMember _mapMemberDetail(MemberDetailDto member) {
    return CommunityMember(
      userId: member.userId,
      name: member.userName,
      role: member.role,
      joinStatus: member.joinStatus,
      status: joinStatusLabelAr(member.joinStatus),
      statusColor: joinStatusColor(member.joinStatus),
    );
  }

  String _buildMembersPreviewFromDetails(List<MemberDetailDto> members) {
    if (members.isEmpty) return '';
    return members
        .map((member) => member.userName)
        .where((name) => name.trim().isNotEmpty)
        .take(3)
        .join(' , ');
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((
  ref,
) {
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
  return state.communities.where((c) => c.title.contains(query)).toList();
});

final communityMembersDetailProvider =
    FutureProvider.family<List<MemberDetailDto>, String>((ref, communityId) {
      final ds = ref.watch(communityRemoteDataSourceProvider);
      return ds.getMembers(communityId);
    });

final communityDetailProvider = FutureProvider.family<CommunityDetail?, String>(
  (ref, communityId) {
    final ds = ref.watch(communityRemoteDataSourceProvider);
    return ds.fetchCommunityById(communityId);
  },
);

final pendingJoinRequestsProvider =
    FutureProvider.family<List<JoinRequestDto>, String>((ref, communityId) {
  final ds = ref.watch(communityRemoteDataSourceProvider);
  return ds.getPendingRequests(communityId);
});

final communitySosHistoryProvider =
    FutureProvider.family<List<SosHistoryItem>, String>((ref, communityId) {
  final ds = ref.watch(communityRemoteDataSourceProvider);
  return ds.fetchSosHistory(communityId);
});
