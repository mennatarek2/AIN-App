import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../models/member_detail.dart';
import '../../utils/community_helpers.dart';
import '../../utils/community_permissions.dart';
import '../providers/communities_provider.dart';
import '../widgets/community_dialogs.dart';

/// Full member profile with location info, reminders, and role-based actions.
class MemberDetailsPage extends ConsumerStatefulWidget {
  const MemberDetailsPage({
    super.key,
    required this.memberDetail,
    required this.communityId,
    required this.currentUserId,
    this.myRole,
  });

  final MemberDetailDto memberDetail;
  final String communityId;
  final String currentUserId;
  final CommunityRole? myRole;

  @override
  ConsumerState<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends ConsumerState<MemberDetailsPage> {
  bool _isSendingReminder = false;
  String? _reminderFeedback;

  MemberDetailDto get _member => widget.memberDetail;

  bool get _isSelf => _member.userId == widget.currentUserId;

  bool get _isOwnerTarget => _member.role == CommunityRole.owner;

  bool get _canManage => CommunityPermissions.canManageMembers(widget.myRole);

  bool get _canChangeRoles =>
      CommunityPermissions.canChangeRoles(widget.myRole);

  bool get _isAdmin => widget.myRole == CommunityRole.admin;

  bool get _canKick =>
      !_isSelf &&
      ((_canChangeRoles && !_isOwnerTarget) ||
          (_isAdmin && _member.role.index < CommunityRole.admin.index));

  bool get _canChangeRole => _canChangeRoles && !_isSelf && !_isOwnerTarget;

  bool get _canTransfer =>
      _canChangeRoles && !_isSelf && _member.isApproved && !_isOwnerTarget;

  bool get _hasActions => _canKick || _canChangeRole || _canTransfer;

  bool get _showRemindButton => _canManage && !_member.hasLocation && !_isSelf;

  Color get _roleColor => roleBadgeColor(_member.role);

  Color get _statusColor => memberStatusColor(_member.memberStatus);

  String get _statusLabel => memberStatusLabelAr(_member.memberStatus);

  String get _lastLocationText {
    if (!_member.hasLocation) return 'غير محدد';
    return '${_member.locationLatitude!.toStringAsFixed(4)}, '
        '${_member.locationLongitude!.toStringAsFixed(4)}';
  }

  String get _lastSeenText {
    if (!_member.hasLocation) return '';
    final updated = _member.lastLocationUpdatedAt;
    if (updated == null) return 'منذ قليل';
    return 'آخر تحديث ${updated.toLocal()}'.split('.').first;
  }

  Future<void> _sendLocationReminder() async {
    if (_isSendingReminder) return;

    setState(() {
      _isSendingReminder = true;
      _reminderFeedback = null;
    });

    final error = await ref
        .read(communitiesProvider.notifier)
        .sendLocationReminder(
          communityId: widget.communityId,
          memberId: _member.userId,
        );

    if (!mounted) return;
    setState(() => _isSendingReminder = false);

    if (error != null) {
      setState(() => _reminderFeedback = error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }

    setState(() => _reminderFeedback = 'تم إرسال تذكير الموقع');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إرسال تذكير مشاركة الموقع للعضو',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Future<void> _openActionsSheet() async {
    await CommunityDialogs.showMemberActionsSheet(
      context,
      userName: _member.userName,
      onChangeRole: _canChangeRole ? _handleChangeRole : null,
      onKick: _canKick ? _handleKick : null,
      onTransferOwnership: _canTransfer ? _handleTransfer : null,
    );
  }

  Future<void> _handleKick() async {
    final removed = await CommunityMemberActions.kick(
      context: context,
      ref: ref,
      communityId: widget.communityId,
      userId: _member.userId,
      userName: _member.userName,
    );
    if (removed && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _handleChangeRole() async {
    final changed = await CommunityMemberActions.changeRole(
      context: context,
      ref: ref,
      communityId: widget.communityId,
      userId: _member.userId,
      userName: _member.userName,
      currentRole: _member.role,
    );
    if (changed && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _handleTransfer() async {
    final transferred = await CommunityMemberActions.transferOwnership(
      context: context,
      ref: ref,
      communityId: widget.communityId,
      userId: _member.userId,
      userName: _member.userName,
    );
    if (transferred && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'تفاصيل العضو',
            subtitle: _member.userName,
            onBack: () => Navigator.of(context).pop(),
            actions: _hasActions
                ? [
                    IconButton(
                      onPressed: _openActionsSheet,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: context.semantic.textOnPrimary,
                      ),
                      tooltip: 'إجراءات العضو',
                    ),
                  ]
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSurfaceCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: _roleColor.withValues(alpha: 0.2),
                          child: Text(
                            _member.userName.isNotEmpty
                                ? _member.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _roleColor,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _member.userName,
                          textDirection: TextDirection.rtl,
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Chip(
                          label: Text(
                            roleBadgeLabelAr(_member.role),
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _roleColor,
                            ),
                          ),
                          backgroundColor: _roleColor.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: _roleColor.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: _statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _statusLabel,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          formatJoinedDateAr(_member.joinedAt),
                          textDirection: TextDirection.rtl,
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormCard(
                    title: 'الموقع الأخير',
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            _member.hasLocation
                                ? Icons.location_on_outlined
                                : Icons.location_off_outlined,
                            color: _member.hasLocation
                                ? context.colors.primary
                                : context.semantic.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _member.hasLocation
                                ? '$_lastLocationText — $_lastSeenText'
                                : _lastLocationText,
                            textDirection: TextDirection.rtl,
                            style: context.text.bodyMedium?.copyWith(
                              color: context.semantic.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showRemindButton) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isSendingReminder
                            ? null
                            : _sendLocationReminder,
                        icon: _isSendingReminder
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.primary,
                                ),
                              )
                            : Icon(
                                Icons.notifications_active_outlined,
                                color: context.colors.primary,
                              ),
                        label: Text(
                          _isSendingReminder
                              ? 'جاري الإرسال…'
                              : 'تذكير بمشاركة الموقع',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.colors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.colors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    if (_reminderFeedback != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _reminderFeedback!,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall?.copyWith(
                          color: _reminderFeedback!.startsWith('تم')
                              ? context.semantic.success
                              : context.semantic.error,
                        ),
                      ),
                    ],
                  ],
                  if (_hasActions) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppFormCard(
                      title: 'إجراءات الإدارة',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_canChangeRole)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              title: const Text(
                                'تغيير الدور',
                                textDirection: TextDirection.rtl,
                              ),
                              onTap: _handleChangeRole,
                            ),
                          if (_canKick)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.person_remove_outlined,
                                color: context.semantic.error,
                              ),
                              title: Text(
                                'إزالة العضو',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(color: context.semantic.error),
                              ),
                              onTap: _handleKick,
                            ),
                          if (_canTransfer)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.swap_horiz_rounded),
                              title: const Text(
                                'نقل الملكية',
                                textDirection: TextDirection.rtl,
                              ),
                              onTap: _handleTransfer,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
