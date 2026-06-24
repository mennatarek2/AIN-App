import 'package:flutter/material.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/network/api_exception.dart';
import '../models/member_detail.dart';

String joinStatusLabel(JoinStatus? status) => switch (status) {
  JoinStatus.pending => 'Request Pending — waiting for admin approval',
  JoinStatus.approved => 'Member',
  JoinStatus.rejected => 'Request Rejected',
  JoinStatus.banned => 'Banned from community',
  null => 'Not a member',
};

String joinStatusLabelAr(JoinStatus? status) => switch (status) {
  JoinStatus.pending => 'الطلب قيد المراجعة — بانتظار موافقة المشرف',
  JoinStatus.approved => 'عضو',
  JoinStatus.rejected => 'تم رفض الطلب',
  JoinStatus.banned => 'محظور من المجتمع',
  null => 'ليس عضواً',
};

Color joinStatusColor(JoinStatus? status) => switch (status) {
  JoinStatus.pending => const Color(0xFFF59E0B),
  JoinStatus.approved => const Color(0xFF2E8B57),
  JoinStatus.rejected => const Color(0xFFDC2626),
  JoinStatus.banned => const Color(0xFFDC2626),
  null => const Color(0xFF64748B),
};

String roleBadgeLabel(CommunityRole role) => switch (role) {
  CommunityRole.owner => 'Owner',
  CommunityRole.admin => 'Admin',
  CommunityRole.moderator => 'Mod',
  CommunityRole.member => 'Member',
};

String roleBadgeLabelAr(CommunityRole role) => switch (role) {
  CommunityRole.owner => 'مالك',
  CommunityRole.admin => 'مشرف',
  CommunityRole.moderator => 'مراقب',
  CommunityRole.member => 'عضو',
};

Color roleBadgeColor(CommunityRole role) => switch (role) {
  CommunityRole.owner => const Color(0xFFD4AF37),
  CommunityRole.admin => const Color(0xFFF59E0B),
  CommunityRole.moderator => const Color(0xFF3B82F6),
  CommunityRole.member => const Color(0xFF64748B),
};

String memberStatusLabelAr(MemberStatus? status) => switch (status) {
  MemberStatus.active => 'نشط',
  MemberStatus.locationPending => 'بانتظار الموقع',
  MemberStatus.inactive => 'غير نشط',
  null => 'غير محدد',
};

Color memberStatusColor(MemberStatus? status) => switch (status) {
  MemberStatus.active => const Color(0xFF2E8B57),
  MemberStatus.locationPending => const Color(0xFFF59E0B),
  MemberStatus.inactive => const Color(0xFFDC2626),
  null => const Color(0xFF64748B),
};

String formatJoinedDateAr(DateTime joinedAt) {
  final local = joinedAt.toLocal();
  return 'انضم ${local.day}/${local.month}/${local.year}';
}

MemberDetailDto? myMembership(List<MemberDetailDto> members, String myUserId) {
  for (final member in members) {
    if (member.userId == myUserId) return member;
  }
  return null;
}

bool canManageMembers(CommunityRole? myRole) =>
    myRole == CommunityRole.owner || myRole == CommunityRole.admin;

bool canChangeRoles(CommunityRole? myRole) => myRole == CommunityRole.owner;

String communityRoleToApiString(CommunityRole role) => switch (role) {
  CommunityRole.admin => 'Admin',
  CommunityRole.moderator => 'Moderator',
  CommunityRole.member => 'Member',
  CommunityRole.owner => throw ArgumentError('Use transferOwnership instead'),
};

String kickMemberErrorMessageAr(ApiException e) {
  if (e.statusCode == 403) {
    final msg = e.displayMessage.toLowerCase();
    if (msg.contains('owner')) {
      return 'انقل الملكية قبل إزالة هذا العضو';
    }
    if (msg.contains('admin')) {
      return 'فقط المالك يمكنه إزالة مشرف';
    }
    return communityApiUserMessage(e);
  }
  return communityApiUserMessage(e);
}

/// §8 — user-facing community API errors (prefers mapped messages, then detail).
String communityApiUserMessage(ApiException e) {
  final combined = '${e.message} ${e.detail ?? ''}'.toLowerCase();

  switch (e.statusCode) {
    case 400:
      if (combined.contains('invite')) {
        return 'استخدم كود دعوة للانضمام إلى هذا المجتمع';
      }
      if (combined.contains('owner') || combined.contains('transfer')) {
        return 'استخدم نقل الملكية لتغيير المالك';
      }
      if (e.detail != null && e.detail!.trim().isNotEmpty) {
        return e.detail!;
      }
      return e.message;
    case 403:
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
    case 404:
      return 'المجتمع غير موجود';
    case 409:
      if (combined.contains('pending')) {
        return 'لديك طلب انضمام قيد المراجعة';
      }
      if (combined.contains('member') || combined.contains('already')) {
        return 'أنت عضو في هذا المجتمع بالفعل';
      }
      return e.detail ?? e.message;
    default:
      return e.detail ?? e.message;
  }
}
