import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';

enum NotificationVisualCategory {
  critical,
  primary,
  community,
  account,
  success,
  warning,
  muted,
}

class NotificationTypeUi {
  const NotificationTypeUi({
    required this.icon,
    required this.category,
  });

  final IconData icon;
  final NotificationVisualCategory category;

  static NotificationTypeUi forType(NotificationType type) {
    return switch (type) {
      NotificationType.sosTriggered => const NotificationTypeUi(
        icon: Icons.warning_amber_rounded,
        category: NotificationVisualCategory.critical,
      ),
      NotificationType.sosResolved => const NotificationTypeUi(
        icon: Icons.check_circle_outline_rounded,
        category: NotificationVisualCategory.success,
      ),
      NotificationType.sosCancelled => const NotificationTypeUi(
        icon: Icons.cancel_outlined,
        category: NotificationVisualCategory.muted,
      ),
      NotificationType.sosFalseAlarm => const NotificationTypeUi(
        icon: Icons.report_gmailerrorred_outlined,
        category: NotificationVisualCategory.warning,
      ),
      NotificationType.sosExpired => const NotificationTypeUi(
        icon: Icons.timer_off_outlined,
        category: NotificationVisualCategory.muted,
      ),
      NotificationType.reportStatusChanged => const NotificationTypeUi(
        icon: Icons.sync_alt_rounded,
        category: NotificationVisualCategory.primary,
      ),
      NotificationType.reportAssigned => const NotificationTypeUi(
        icon: Icons.assignment_ind_outlined,
        category: NotificationVisualCategory.primary,
      ),
      NotificationType.reportCommented => const NotificationTypeUi(
        icon: Icons.chat_bubble_outline_rounded,
        category: NotificationVisualCategory.primary,
      ),
      NotificationType.communityJoined => const NotificationTypeUi(
        icon: Icons.group_add_rounded,
        category: NotificationVisualCategory.community,
      ),
      NotificationType.communityJoinRequested => const NotificationTypeUi(
        icon: Icons.person_add_alt_1_rounded,
        category: NotificationVisualCategory.community,
      ),
      NotificationType.communityJoinApproved => const NotificationTypeUi(
        icon: Icons.how_to_reg_rounded,
        category: NotificationVisualCategory.success,
      ),
      NotificationType.communityJoinRejected => const NotificationTypeUi(
        icon: Icons.person_off_outlined,
        category: NotificationVisualCategory.warning,
      ),
      NotificationType.communityMemberRemoved => const NotificationTypeUi(
        icon: Icons.group_remove_rounded,
        category: NotificationVisualCategory.warning,
      ),
      NotificationType.communityLocationReminder => const NotificationTypeUi(
        icon: Icons.location_on_outlined,
        category: NotificationVisualCategory.community,
      ),
      NotificationType.communityInvited => const NotificationTypeUi(
        icon: Icons.mail_outline_rounded,
        category: NotificationVisualCategory.community,
      ),
      NotificationType.trustPointsChanged => const NotificationTypeUi(
        icon: Icons.stars_rounded,
        category: NotificationVisualCategory.account,
      ),
      NotificationType.accountVerified => const NotificationTypeUi(
        icon: Icons.verified_rounded,
        category: NotificationVisualCategory.success,
      ),
      NotificationType.passwordChanged => const NotificationTypeUi(
        icon: Icons.lock_reset_rounded,
        category: NotificationVisualCategory.account,
      ),
    };
  }

  Color resolveColor({
    required Color critical,
    required Color primary,
    required Color community,
    required Color account,
    required Color success,
    required Color warning,
    required Color muted,
  }) {
    return switch (category) {
      NotificationVisualCategory.critical => critical,
      NotificationVisualCategory.primary => primary,
      NotificationVisualCategory.community => community,
      NotificationVisualCategory.account => account,
      NotificationVisualCategory.success => success,
      NotificationVisualCategory.warning => warning,
      NotificationVisualCategory.muted => muted,
    };
  }
}
