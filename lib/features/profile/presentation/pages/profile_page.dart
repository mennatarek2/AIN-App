import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/profile_photo_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../social/presentation/widgets/trust_profile_card.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_page.dart';
import 'points_page.dart';
import 'settings_page.dart';
import 'chatbot_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileAsyncProvider);
    final profile = ref.watch(profileProvider);
    final trustAsync = ref.watch(myTrustProvider);
    final trust = trustAsync.valueOrNull;
    final badge = TrustBadge.fromString(trust?.badge ?? profile?.badge);
    final photoUrl = ref.watch(profilePhotoUrlProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: profileAsync.when(
        loading: () =>
            const AppLoadingView(message: 'جاري تحميل الملف الشخصي...'),
        error: (_, __) => AppErrorView(
          message: 'تعذر تحميل الملف الشخصي',
          onRetry: () => ref.read(profileAsyncProvider.notifier).refresh(),
        ),
        data: (userProfile) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: context.heroGradient,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.xxl),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -30,
                          left: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.semantic.textOnPrimary
                                  .withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: -10,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.semantic.textOnPrimary
                                  .withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: 40,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.semantic.textOnPrimary
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenHorizontal,
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: Text(
                                    'حسابي',
                                    style: context.text.titleLarge?.copyWith(
                                      color: context.semantic.textOnPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            if (!embeddedInShell)
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: context.semantic.textOnPrimary,
                                  size: 20,
                                ),
                              ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 120,
                    child: _ProfileIdentityCard(
                      profile: userProfile,
                      photoUrl: photoUrl,
                      badge: badge,
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  110,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PointsPage(),
                        ),
                      ),
                      child: const TrustProfileCard(userId: 'me'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: 'الحساب',
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.person_outline_rounded,
                          label: 'تعديل الملف الشخصي',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          ),
                        ),
                        _SettingsTileData(
                          icon: Icons.lock_outline_rounded,
                          label: 'تغيير كلمة المرور',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.changePassword),
                        ),
                        _SettingsTileData(
                          icon: Icons.assignment_outlined,
                          label: 'بلاغاتي',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.myReports),
                        ),
                        _SettingsTileData(
                          icon: Icons.settings_outlined,
                          label: 'الإعدادات',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          ),
                        ),
                        _SettingsTileData(
                          icon: Icons.smart_toy_outlined,
                          label: 'المساعد الذكي',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatbotPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    _SettingsSection(
                      title: 'التطبيق',
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.info_outline_rounded,
                          label: 'عن التطبيق',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'عين',
                              applicationVersion: '1.0.0',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    _SettingsSection(
                      title: 'الأمان',
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.logout_rounded,
                          label: 'تسجيل الخروج',
                          color: context.semantic.error,
                          onTap: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary,
                    context.colors.primary.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.semantic.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: context.semantic.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'تسجيل الخروج',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'هل تريد تسجيل الخروج من حسابك؟',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.semantic.error,
                          ),
                          child: const Text('خروج'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.profile,
    required this.photoUrl,
    required this.badge,
  });

  final dynamic profile;
  final String? photoUrl;
  final TrustBadge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.semantic.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: context.semantic.borderSubtle),
        boxShadow: context.cardShadows,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ProfilePhotoImage(
              imagePath: photoUrl,
              fit: BoxFit.cover,
              width: 88,
              height: 88,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile?.name ?? '',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (profile?.username.trim().isNotEmpty == true)
            Text('@${profile!.username}', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(profile?.email ?? '', style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: badge.color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badge.emoji),
                const SizedBox(width: 6),
                Text(
                  badge.label,
                  style: TextStyle(
                    color: badge.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTileData {
  const _SettingsTileData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.tiles});

  final String title;
  final List<_SettingsTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: title,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.semantic.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.semantic.borderSubtle),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                _SettingsTile(data: tiles[i]),
                if (i < tiles.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    endIndent: AppSpacing.md,
                    color: context.semantic.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingsTileData data;

  @override
  Widget build(BuildContext context) {
    final color = data.color ?? context.colors.onSurface;

    return ListTile(
      onTap: data.onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(data.icon, color: color, size: 20),
      ),
      title: Text(
        data.label,
        textDirection: TextDirection.rtl,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: context.semantic.textMuted,
      ),
    );
  }
}
