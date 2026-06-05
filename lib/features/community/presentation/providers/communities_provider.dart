import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/community_remote_data_source.dart';
import '../pages/community_info_page.dart';

class Community {
  const Community({
    required this.id,
    required this.title,
    required this.membersPreview,
    required this.iconPath,
    required this.members,
  });

  final String id;
  final String title;
  final String membersPreview;
  final String iconPath;
  final List<CommunityMember> members;
}

class CommunitiesState {
  const CommunitiesState({
    required this.communities,
    required this.searchQuery,
  });

  final List<Community> communities;
  final String searchQuery;

  CommunitiesState copyWith({
    List<Community>? communities,
    String? searchQuery,
  }) {
    return CommunitiesState(
      communities: communities ?? this.communities,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CommunitiesNotifier extends StateNotifier<CommunitiesState> {
  CommunitiesNotifier(this._remoteDataSource) : super(_initialState()) {
    _loadFromApi();
  }

  final CommunityRemoteDataSource _remoteDataSource;

  static CommunitiesState _initialState() {
    return CommunitiesState(
      communities: [
        Community(
          id: 'comm-1',
          title: 'My Friends',
          membersPreview: 'laila , Amr , Alaa........',
          iconPath: 'assets/images/frinds_comm.png',
          members: const [
            CommunityMember(
              name: 'Laila Ahmed',
              status: 'آمن • منذ دقيقتين',
              statusColor: Color(0xFF2E8B57),
            ),
            CommunityMember(
              name: 'Amr Khaled',
              status: 'قريب من حادث • منذ 5 دقائق',
              statusColor: Color(0xFFD23B3B),
            ),
            CommunityMember(
              name: 'Alaa Mahmoud',
              status: 'قريب من حادث • منذ 5 دقائق',
              statusColor: Color(0xFFD23B3B),
            ),
          ],
        ),
        Community(
          id: 'comm-2',
          title: 'My Family',
          membersPreview: 'Mahmoud , Abdulrahman........',
          iconPath: 'assets/images/family_comm.png',
          members: const [
            CommunityMember(
              name: 'Mahmoud',
              status: 'آمن • منذ 3 دقائق',
              statusColor: Color(0xFF2E8B57),
            ),
            CommunityMember(
              name: 'Abdulrahman',
              status: 'قريب من حادث • منذ 6 دقائق',
              statusColor: Color(0xFFD23B3B),
            ),
            CommunityMember(
              name: 'Sara',
              status: 'آمن • منذ 2 دقيقة',
              statusColor: Color(0xFF2E8B57),
            ),
          ],
        ),
      ],
      searchQuery: '',
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void addCommunity(Community community) {
    final updatedCommunities = List<Community>.from(state.communities);
    updatedCommunities.add(community);
    state = state.copyWith(communities: updatedCommunities);
  }

  Future<void> createCommunity({
    required String name,
    required String description,
  }) async {
    await _remoteDataSource.createCommunity(name: name, description: description);
    await _loadFromApi();
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

  Future<void> _loadFromApi() async {
    try {
      final communities = await _remoteDataSource.fetchAllCommunities();
      if (communities.isEmpty || !mounted) return;

      final mapped = <Community>[];
      for (final item in communities) {
        final members = await _remoteDataSource.fetchCommunityMembers(item.id);
        mapped.add(
          Community(
            id: item.id,
            title: item.name,
            membersPreview: _buildMembersPreview(members),
            iconPath: 'assets/images/family_comm.png',
            members: members
                .map(
                  (member) => CommunityMember(
                    name: member.displayName?.trim().isNotEmpty == true
                        ? member.displayName!
                        : member.email,
                    status: 'عضو',
                    statusColor: const Color(0xFF2E8B57),
                  ),
                )
                .toList(),
          ),
        );
      }

      if (!mounted || mapped.isEmpty) return;
      state = state.copyWith(communities: mapped);
    } catch (_) {
      // Keep seeded fallback data if the API fails.
    }
  }

  String _buildMembersPreview(List<CommunityMemberApiModel> members) {
    if (members.isEmpty) return '';
    final names = members
        .map((member) => member.displayName ?? member.email)
        .where((name) => name.trim().isNotEmpty)
        .take(3)
        .toList();
    return names.join(' , ');
  }
}

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  final userLocal = ref.watch(userLocalDataSourceProvider);
  return CommunityRemoteDataSource(
    ref.watch(apiClientProvider),
    readToken: userLocal.getCachedToken,
  );
});

final communitiesProvider =
    StateNotifierProvider<CommunitiesNotifier, CommunitiesState>((ref) {
      return CommunitiesNotifier(ref.watch(communityRemoteDataSourceProvider));
    });

final filteredCommunitiesProvider = Provider<List<Community>>((ref) {
  final state = ref.watch(communitiesProvider);
  final query = state.searchQuery;

  if (query.isEmpty) {
    return state.communities;
  }

  return state.communities
      .where((community) => community.title.contains(query))
      .toList();
});
