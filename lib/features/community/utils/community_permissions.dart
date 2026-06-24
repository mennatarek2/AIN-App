import '../models/enums/community_enums.dart';
import '../models/member_detail.dart';

class CommunityPermissions {
  static CommunityRole? myRole(List<MemberDetailDto> members, String myUserId) {
    try {
      return members.firstWhere((m) => m.userId == myUserId).role;
    } catch (_) {
      return null;
    }
  }

  static bool canManageMembers(CommunityRole? role) =>
      role != null && role.index >= CommunityRole.admin.index;

  static bool canChangeRoles(CommunityRole? role) => role == CommunityRole.owner;

  static bool canManageCodes(CommunityRole? role) =>
      role != null && role.index >= CommunityRole.admin.index;

  static bool canArchive(CommunityRole? role) => role == CommunityRole.owner;

  static bool canTransferOwnership(CommunityRole? role) =>
      role == CommunityRole.owner;

  static bool canViewJoinRequests(CommunityRole? role) =>
      role != null && role.index >= CommunityRole.admin.index;

  static bool canViewMemberPII(CommunityRole? role) =>
      role != null && role.index >= CommunityRole.admin.index;

  static bool canEditCommunity(CommunityRole? role) =>
      role != null && role.index >= CommunityRole.admin.index;
}
