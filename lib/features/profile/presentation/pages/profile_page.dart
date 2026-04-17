import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'chatbot_page.dart';
import 'edit_profile_page.dart';
import 'points_page.dart';
import 'settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'هل تريد تسجيل الخروج ؟',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40 * 0.525,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 170,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0099FF), Color(0xFF66C8FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'نعم',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 40 * 0.525,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 170,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.textPrimaryLight,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'لا',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 40 * 0.525,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060C3A)
          : AppColors.backgroundLight,
      body: Column(
        children: [
          _ProfileHeader(onBack: () => Navigator.of(context).pop()),
          const SizedBox(height: 30),
          _ProfileAvatar(imagePath: currentUser?.profileImageUrl),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 40 * 0.525,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFF3F6F9)
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.circle, size: 12, color: profile.levelDotColor),
              const SizedBox(width: 8),
              Text(
                profile.level,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFFF3F6F9)
                      : const Color(0x80060C3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                _ProfileActionRow(
                  title: 'تعديل الملف الشخصي',
                  trailingIcon: Icons.edit_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                _ProfileActionRow(
                  title: 'النقاط',
                  trailingIcon: Icons.star_border_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PointsPage()),
                    );
                  },
                ),
                _ProfileActionRow(
                  title: 'الإعدادات',
                  trailingIcon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                _ProfileActionRow(
                  title: 'المساعد الذكي',
                  trailingIcon: Icons.support_agent_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotPage()),
                    );
                  },
                ),
                _ProfileActionRow(
                  title: 'تسجيل الخروج',
                  trailingIcon: Icons.logout_outlined,
                  withDivider: false,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 52,
            child: GestureDetector(
              onTap: onBack,
              child: Icon(
                Icons.arrow_forward_ios,
                color: isDark
                    ? const Color(0xFFF3F6F9)
                    : AppColors.textPrimaryLight,
                size: 24,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 0.32),
              child: Text(
                'حسابي',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 40 * 0.525,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF3F6F9)
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFFB7CAE1) : const Color(0x80415789),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBAD6F4), Color(0xFFB8D0EE)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedAppImage(
        imagePath: imagePath?.trim().isNotEmpty == true
            ? imagePath!
            : 'assets/images/user_chatbot.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.title,
    required this.trailingIcon,
    this.withDivider = true,
    this.onTap,
  });

  final String title;
  final IconData trailingIcon;
  final bool withDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark
        ? const Color(0xFFF3F6F9)
        : AppColors.textPrimaryLight;

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: InkWell(
            onTap: onTap,
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Icon(Icons.chevron_right, color: rowColor, size: 30),
                const Spacer(),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(trailingIcon, color: rowColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        color: rowColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (withDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFFF3F6F9) : const Color(0x33415789),
          ),
      ],
    );
  }
}
