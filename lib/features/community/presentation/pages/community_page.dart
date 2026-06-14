import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/signalr_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../providers/communities_provider.dart';
import 'community_info_page.dart';
import 'create_community_page.dart';
import 'join_by_code_page.dart';

// ─── Color constants ──────────────────────────────────────────────────────────

const _accentRed = Color(0xFFEF4444);
const _accentBlue = AppColors.primary;

// ─── Community Page ───────────────────────────────────────────────────────────

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  @override
  void initState() {
    super.initState();
    ref.read(homeNavigationProvider.notifier).setSelectedIndex(1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinSignalRGroups());
  }

  Future<void> _joinSignalRGroups() async {
    final manager = ref.read(signalRManagerProvider);
    final communities = ref.read(communitiesProvider).communities;
    for (final c in communities) {
      await manager.joinCommunityGroup(c.id);
    }
  }

  void _openJoinByCode() async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JoinByCodePage()),
    );
    if (joined == true && mounted) {
      await _joinSignalRGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(communitiesProvider);
    final communities = ref.watch(filteredCommunitiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg = isDark ? const Color(0xFF0D1445) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D6B) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _Header(
            isDark: isDark,
            textPrimary: textPrimary,
            onCreateTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateCommunityPage()),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(communitiesProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  // ── My communities section header ──────────────────────────
                  _SectionHeader(label: 'مجتمعاتي', textColor: textPrimary),
                  const SizedBox(height: 12),

                  if (commState.isLoading && communities.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (communities.isEmpty)
                    _EmptyState(
                      isDark: isDark,
                      textSecondary: textSecondary,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                    )
                  else
                    ...communities.map((c) {
                      final sosCount =
                          commState.activeSosCounts[c.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CommunityCard(
                          community: c,
                          activeSosCount: sosCount,
                          isDark: isDark,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunityInfoPage(
                                communityId: c.id,
                                communityName: c.title,
                                members: c.members,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  Divider(color: cardBorder),
                  const SizedBox(height: 24),

                  // ── Location Pending Banner ────────────────────────────────
                  if (commState.showLocationBanner)
                    _LocationPendingBanner(
                      onShareLocation: () {
                        ref
                            .read(communitiesProvider.notifier)
                            .onLocationShared();
                        // TODO: navigate to location permission screen
                      },
                      onDismiss: () => ref
                          .read(communitiesProvider.notifier)
                          .dismissLocationBanner(),
                    ),

                  // ── Discover / Join section ────────────────────────────────
                  _SectionHeader(
                    label: 'اكتشف مجتمعات',
                    textColor: textPrimary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'انضم إلى مجتمع بكود الدعوة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Join by invite code button
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _openJoinByCode,
                      icon: const Icon(Icons.key_rounded, size: 20),
                      label: const Text(
                        'انضمام بكود الدعوة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentBlue,
                        side: const BorderSide(color: _accentBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: ref.watch(homeNavigationProvider),
        onTap: (index) {
          if (index == 1) return;
          ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
          navigateFromBottomNav(context, index);
        },
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.textPrimary,
    required this.onCreateTap,
  });

  final bool isDark;
  final Color textPrimary;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, 0.32),
              child: Text(
                'مجتمعي',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCreateTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'إنشاء',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDark,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  final bool isDark;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد مجتمعات بعد',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أنشئ مجتمعاً جديداً أو انضم إلى مجتمع موجود',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Community Card ───────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.activeSosCount,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final Community community;
  final int activeSosCount;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  Color get _avatarColor {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[community.title.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSos = activeSosCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasActiveSos ? _accentRed : cardBorder,
          width: hasActiveSos ? 2 : 1,
        ),
        boxShadow: hasActiveSos
            ? [
                BoxShadow(
                  color: _accentRed.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    community.title.isNotEmpty
                        ? community.title[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              community.title,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (hasActiveSos) ...[
                            const SizedBox(width: 8),
                            _SosBadge(count: activeSosCount),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} عضو',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      if (community.membersPreview.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          community.membersPreview,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left,
                  color: textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SOS Badge ────────────────────────────────────────────────────────────────

class _SosBadge extends StatelessWidget {
  const _SosBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _accentRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.crisis_alert, color: Colors.white, size: 11),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location Pending Banner ──────────────────────────────────────────────────

class _LocationPendingBanner extends StatelessWidget {
  const _LocationPendingBanner({
    required this.onShareLocation,
    required this.onDismiss,
  });

  final VoidCallback onShareLocation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.location_off_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'شارك موقعك لتفعيل نداءات الاستغاثة في مجتمعك',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onShareLocation,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'مشاركة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
