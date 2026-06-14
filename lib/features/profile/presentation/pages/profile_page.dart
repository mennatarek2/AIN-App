import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_app_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/presentation/pages/community_page.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileAsyncProvider);
    final profile = ref.watch(profileProvider);
    final trustAsync = ref.watch(myTrustProvider);

    // Derive trust info: prefer API trust endpoint, fall back to profile badge
    final trust = trustAsync.valueOrNull;
    final pts = trust?.trustPoints ?? profile?.points ?? 0;
    // Use API badge from profile (server-computed) as primary source
    final badge = trust?.badge
        ?? TrustBadge.fromString(profile?.badge)
        ?? TrustBadge.fromPoints(pts);
    final totalReports = trust?.totalReports ?? 0;
    final resolvedReports = trust?.resolvedReports ?? 0;
    final pendingReports = trust?.pendingReports ?? 0;

    final bg = isDark ? const Color(0xFF060C3A) : const Color(0xFFF5F7FA);
    final cardBg = isDark ? const Color(0xFF0D1445) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D6B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF3F6F9) : AppColors.textPrimaryLight;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: textSecondary),
              const SizedBox(height: 12),
              Text('تعذر تحميل الملف الشخصي',
                  style: TextStyle(color: textPrimary, fontSize: 15)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () =>
                    ref.read(profileAsyncProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                label: const Text('إعادة المحاولة',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (userProfile) => CustomScrollView(
          slivers: [
            // ── Header (SliverAppBar) ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor:
                  isDark ? const Color(0xFF0A0F2E) : AppColors.primary,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  ),
                  tooltip: 'تعديل الملف',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHero(
                  profile: userProfile,
                  badge: badge,
                  isDark: isDark,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    // ── Trust Points Progress Card ─────────────────────
                    _TrustProgressCard(
                      pts: pts,
                      badge: badge,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    const SizedBox(height: 14),

                    // ── Stats Row ──────────────────────────────────────
                    _StatsRow(
                      total: totalReports,
                      resolved: resolvedReports,
                      pending: pendingReports,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    const SizedBox(height: 20),

                    // ── Settings: Account ─────────────────────────────
                    _SettingsSection(
                      title: 'الحساب',
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.person_outline_rounded,
                          label: 'تعديل الملف الشخصي',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const EditProfilePage()),
                          ),
                        ),
                        _SettingsTileData(
                          icon: Icons.lock_outline_rounded,
                          label: 'تغيير كلمة المرور',
                          onTap: () =>
                              Navigator.of(context).pushNamed('/change-password'),
                        ),
                        _SettingsTileData(
                          icon: Icons.assignment_outlined,
                          label: 'بلاغاتي',
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.myReports),
                        ),
                        _SettingsTileData(
                          icon: Icons.group_outlined,
                          label: 'مجتمعاتي',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CommunityPage()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Settings: App ─────────────────────────────────
                    _SettingsSection(
                      title: 'التطبيق',
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.notifications_outlined,
                          label: 'الإشعارات',
                          onTap: () => Navigator.of(context)
                              .pushNamed('/notifications'),
                        ),
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

                    const SizedBox(height: 12),

                    // ── Settings: Security ────────────────────────────
                    _SettingsSection(
                      title: 'الأمان',
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      tiles: [
                        _SettingsTileData(
                          icon: Icons.logout_rounded,
                          label: 'تسجيل الخروج',
                          color: const Color(0xFFEF4444),
                          onTap: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ────────────────────────────────────────────────────────

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الخروج',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'هل تريد تسجيل الخروج من حسابك؟',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.primary, fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('خروج',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

// ─── Profile Hero (collapsible header) ───────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.badge,
    required this.isDark,
  });

  final dynamic profile;
  final TrustBadge badge;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasImage = profile?.profilePhotoUrl != null &&
        (profile.profilePhotoUrl as String).isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0A0F2E), const Color(0xFF1E2D6B)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? CachedAppImage(
                      imagePath: profile.profilePhotoUrl as String,
                      fit: BoxFit.cover,
                    )
                  : Image.asset('assets/images/user_chatbot.png',
                      fit: BoxFit.cover),
            ),

            const SizedBox(height: 10),

            // Name
            Text(
              profile?.name ?? 'بلا اسم',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              profile?.email ?? '',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),

            const SizedBox(height: 10),

            // Trust badge chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: badge.color.withValues(alpha: 0.50), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(badge.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: badge.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Trust Progress Card ──────────────────────────────────────────────────────

class _TrustProgressCard extends StatelessWidget {
  const _TrustProgressCard({
    required this.pts,
    required this.badge,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  final int pts;
  final TrustBadge badge;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final progress = badge.progressFor(pts);
    final toNext = badge.pointsToNext(pts);
    final isMax = badge == TrustBadge.guardian;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: badge.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'نقاط الثقة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pts نقطة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badge.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: badge.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(badge.color),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isMax
                  ? '🏆 أعلى مستوى — حارس'
                  : '$toNext نقطة للمستوى التالي',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.resolved,
    required this.pending,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  final int total;
  final int resolved;
  final int pending;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'البلاغات المقدمة',
            value: total,
            icon: Icons.assignment_outlined,
            color: AppColors.primary,
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'تم الحل',
            value: resolved,
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'قيد المراجعة',
            value: pending,
            icon: Icons.hourglass_bottom_rounded,
            color: const Color(0xFFF59E0B),
            cardBg: cardBg,
            cardBorder: cardBorder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 10, color: textSecondary),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────

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
  const _SettingsSection({
    required this.title,
    required this.tiles,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String title;
  final List<_SettingsTileData> tiles;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                _SettingsTile(
                  data: tiles[i],
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                if (i < tiles.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 16,
                    color: cardBorder,
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
  const _SettingsTile({
    required this.data,
    required this.textPrimary,
    required this.textSecondary,
  });

  final _SettingsTileData data;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final color = data.color ?? textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: textSecondary.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
