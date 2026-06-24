import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../utils/community_helpers.dart';
import '../providers/communities_provider.dart';

/// Centralized confirmation dialogs and member-management flows for the
/// Community Module.
class CommunityDialogs {
  CommunityDialogs._();

  static Future<bool> confirmLeave(
    BuildContext context, {
    required String communityName,
    bool isOwner = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'مغادرة المجتمع',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد أنك تريد مغادرة "$communityName"؟',
              textDirection: TextDirection.rtl,
            ),
            if (isOwner) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أنت مالك هذا المجتمع — يُنصح بنقل الملكية إلى عضو آخر قبل المغادرة.',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.semantic.error,
            ),
            child: Text(
              'نعم، مغادرة',
              style: TextStyle(color: ctx.semantic.textOnPrimary),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmDeleteCommunity(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف المجتمع',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف هذا المجتمع؟ لا يمكن التراجع عن هذا الإجراء.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.semantic.error,
            ),
            child: Text(
              'حذف',
              style: TextStyle(color: ctx.semantic.textOnPrimary),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmKickMember(
    BuildContext context, {
    required String userName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إزالة العضو',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'إزالة $userName؟ لن يتمكن من الانضمام مجدداً.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ctx.semantic.error),
            child: Text(
              'إزالة',
              style: TextStyle(color: ctx.semantic.textOnPrimary),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmTransferOwnership(
    BuildContext context, {
    required String userName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'نقل الملكية',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'نقل الملكية إلى $userName؟ ستصبح مشرفاً وتفقد صلاحيات المالك.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نقل الملكية'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmRejectJoinRequest(
    BuildContext context, {
    required String userName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'رفض طلب الانضمام',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من رفض طلب $userName؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ctx.semantic.error),
            child: Text(
              'رفض',
              style: TextStyle(color: ctx.semantic.textOnPrimary),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmRevokeInviteCode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إلغاء كود الدعوة',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'لن يتمكن أحد من الانضمام باستخدام الكود الحالي.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool> confirmRegenerateInviteCode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إعادة توليد كود الدعوة',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'سيتم إنشاء كود جديد وسيتوقف الكود الحالي عن العمل.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('توليد كود جديد'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<CommunityRole?> pickMemberRole(
    BuildContext context, {
    required String userName,
    required CommunityRole currentRole,
  }) {
    const roles = [
      CommunityRole.member,
      CommunityRole.moderator,
      CommunityRole.admin,
    ];

    return showDialog<CommunityRole>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تغيير دور $userName',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles
              .where((role) => role != currentRole)
              .map(
                (role) => ListTile(
                  title: Text(
                    roleBadgeLabelAr(role),
                    textDirection: TextDirection.rtl,
                  ),
                  onTap: () => Navigator.pop(ctx, role),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static Future<void> showMemberActionsSheet(
    BuildContext context, {
    required String userName,
    required VoidCallback? onChangeRole,
    required VoidCallback? onKick,
    required VoidCallback? onTransferOwnership,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'إجراءات العضو — $userName',
                textDirection: TextDirection.rtl,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onChangeRole != null)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text(
                  'تغيير الدور',
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onChangeRole();
                },
              ),
            if (onKick != null)
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: ctx.semantic.error),
                title: Text(
                  'إزالة العضو',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: ctx.semantic.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onKick();
                },
              ),
            if (onTransferOwnership != null)
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text(
                  'نقل الملكية',
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onTransferOwnership();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Executes member-management API calls with dialogs and snackbars.
class CommunityMemberActions {
  CommunityMemberActions._();

  static Future<bool> kick({
    required BuildContext context,
    required WidgetRef ref,
    required String communityId,
    required String userId,
    required String userName,
  }) async {
    if (!await CommunityDialogs.confirmKickMember(context, userName: userName)) {
      return false;
    }
    final error = await ref
        .read(communitiesProvider.notifier)
        .kickMember(communityId, userId);
    if (!context.mounted) return false;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إزالة العضو', textDirection: TextDirection.rtl),
      ),
    );
    return true;
  }

  static Future<bool> changeRole({
    required BuildContext context,
    required WidgetRef ref,
    required String communityId,
    required String userId,
    required String userName,
    required CommunityRole currentRole,
  }) async {
    final selected = await CommunityDialogs.pickMemberRole(
      context,
      userName: userName,
      currentRole: currentRole,
    );
    if (selected == null || !context.mounted) return false;

    final error = await ref
        .read(communitiesProvider.notifier)
        .changeMemberRole(communityId, userId, selected);
    if (!context.mounted) return false;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تغيير الدور', textDirection: TextDirection.rtl),
      ),
    );
    return true;
  }

  static Future<bool> transferOwnership({
    required BuildContext context,
    required WidgetRef ref,
    required String communityId,
    required String userId,
    required String userName,
  }) async {
    if (!await CommunityDialogs.confirmTransferOwnership(
      context,
      userName: userName,
    )) {
      return false;
    }
    final error = await ref
        .read(communitiesProvider.notifier)
        .transferOwnership(communityId, userId);
    if (!context.mounted) return false;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نقل الملكية بنجاح', textDirection: TextDirection.rtl),
      ),
    );
    return true;
  }
}
