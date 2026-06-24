import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/signalr_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../home/presentation/pages/your_location_page.dart';
import '../../../home/presentation/providers/home_navigation_provider.dart';
import '../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../widgets/location_pending_banner.dart';
import '../providers/communities_provider.dart';
import 'community_discover_page.dart';
import 'community_info_page.dart';
import 'create_community_page.dart';
import 'join_by_code_page.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.embeddedInShell) {
      ref.read(homeNavigationProvider.notifier).setSelectedIndex(1);
    }
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
    final joined = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const JoinByCodePage()));
    if (joined == true && mounted) {
      await _joinSignalRGroups();
    }
  }

  Future<void> _openDiscover() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityDiscoverPage()),
    );
    if (!mounted) return;
    ref.read(communitiesProvider.notifier).clearSearchResults();
  }

  void _openCreateCommunity() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCommunityPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(communitiesProvider);
    final communities = ref.watch(filteredCommunitiesProvider);

    // Drive the MaterialBanner from state imperatively.
    ref.listen<CommunitiesState>(communitiesProvider, (prev, next) {
      if (!mounted) return;
      if (next.showLocationBanner && prev?.showLocationBanner != true) {
        LocationPendingBanner.show(
          context,
          onSetLocation: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const YourLocationPage()),
            );
            if (!context.mounted) return;
            ref.read(communitiesProvider.notifier).onLocationShared();
          },
        );
      } else if (!next.showLocationBanner && prev?.showLocationBanner == true) {
        LocationPendingBanner.hide(context);
      }
    });

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppDashboardHeader(
            title: 'مجتمعي',
            subtitle: '${communities.length} مجتمع${communities.length == 1 ? '' : 'ات'}',
            trailing: [
              Material(
                color: context.semantic.textOnPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: _openCreateCommunity,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: context.semantic.textOnPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'إنشاء',
                          style: context.text.labelMedium?.copyWith(
                            color: context.semantic.textOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(communitiesProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _FeaturedJoinCard(onTap: _openJoinByCode),
                  _DiscoverCard(onTap: _openDiscover),
                  const AppSectionHeader(title: 'مجتمعاتي'),
                  if (commState.isLoading && communities.isEmpty)
                    ...List.generate(
                      3,
                      (i) => const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          AppSpacing.sm,
                        ),
                        child: CommunityCardSkeleton(),
                      ),
                    )
                  else if (communities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: const _EmptyState(),
                    )
                  else
                    ...communities.map((c) {
                      final sosCount = commState.activeSosCounts[c.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          AppSpacing.sm,
                        ),
                        child: _CommunityCard(
                          community: c,
                          activeSosCount: sosCount,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunityInfoPage(
                                communityId: c.id,
                                communityName: c.title,
                                members: c.members,
                                inviteCode: c.inviteCode,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (commState.showLocationBanner) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: LocationPendingBannerCard(
                        onShareLocation: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const YourLocationPage(),
                            ),
                          );
                          if (!context.mounted) return;
                          ref
                              .read(communitiesProvider.notifier)
                              .onLocationShared();
                        },
                        onDismiss: () => ref
                            .read(communitiesProvider.notifier)
                            .dismissLocationBanner(),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.embeddedInShell
          ? null
          : BottomNavBar(
              selectedIndex: ref.watch(homeNavigationProvider),
              onTap: (index) {
                if (index == 1) return;
                ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
                navigateFromBottomNav(context, ref, index);
              },
            ),
    );
  }
}

class _FeaturedJoinCard extends StatelessWidget {
  const _FeaturedJoinCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: AppSurfaceCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                context.colors.primary.withValues(alpha: 0.08),
                context.colors.secondary.withValues(alpha: 0.12),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: context.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.key_rounded,
                  color: context.semantic.textOnPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'انضم بكود الدعوة',
                      textDirection: TextDirection.rtl,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'اطلب الكود من مشرف المجتمع وانضم فوراً',
                      textDirection: TextDirection.rtl,
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: context.colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: AppSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.colors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.explore_rounded,
                color: context.colors.secondary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اكتشف مجتمعات',
                    textDirection: TextDirection.rtl,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'ابحث عن أحياء ومباني وانضم إليها',
                    textDirection: TextDirection.rtl,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_outlined,
              size: 32,
              color: context.colors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد مجتمعات بعد',
            textDirection: TextDirection.rtl,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'أنشئ مجتمعاً جديداً أو انضم إلى مجتمع موجود',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.activeSosCount,
    required this.onTap,
  });

  final Community community;
  final int activeSosCount;
  final VoidCallback onTap;

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  Color _colorFor(String seed, int index) =>
      _avatarColors[(seed.hashCode.abs() + index) % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final hasActiveSos = activeSosCount > 0;
    final sosColor = semantic.sos;

    return AppSurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: hasActiveSos
              ? sosColor.withValues(alpha: 0.06)
              : Colors.transparent,
          border: hasActiveSos
              ? Border.all(color: sosColor, width: 2)
              : null,
          boxShadow: hasActiveSos
              ? [
                  BoxShadow(
                    color: sosColor.withValues(alpha: 0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasActiveSos)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: sosColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.crisis_alert_rounded, color: sosColor, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'نداء طوارئ نشط في هذا المجتمع',
                        textDirection: TextDirection.rtl,
                        style: context.text.labelMedium?.copyWith(
                          color: sosColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SosBadge(count: activeSosCount),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _colorFor(community.title, 0),
                        _colorFor(community.title, 1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    community.title.isNotEmpty
                        ? community.title[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: context.semantic.textOnPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              community.title,
                              textDirection: TextDirection.rtl,
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${community.memberCount} عضو',
                        textDirection: TextDirection.rtl,
                        style: context.text.bodySmall?.copyWith(
                          color: semantic.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: semantic.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
            if (community.members.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _MemberAvatarStack(
                members: community.members,
                memberCount: community.memberCount,
              ),
            ] else if (community.membersPreview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                community.membersPreview,
                textDirection: TextDirection.rtl,
                style: context.text.labelSmall?.copyWith(
                  color: semantic.textMuted.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({
    required this.members,
    required this.memberCount,
  });

  final List<CommunityMember> members;
  final int memberCount;

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    const maxVisible = 4;
    final visible = members.take(maxVisible).toList();
    final extra = memberCount > maxVisible ? memberCount - maxVisible : 0;
    final stackWidth = (visible.length + (extra > 0 ? 1 : 0)) * 24.0 + 16;

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: stackWidth,
          height: 32,
          child: Stack(
            children: [
              ...visible.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return Positioned(
                  right: i * 24.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _avatarColors[i % _avatarColors.length],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.semantic.surfaceContainer,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.semantic.textOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
              if (extra > 0)
                Positioned(
                  right: maxVisible * 24.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.semantic.borderStrong,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.semantic.surfaceContainer,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: TextStyle(
                        color: context.semantic.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'أعضاء نشطون',
          textDirection: TextDirection.rtl,
          style: context.text.labelSmall?.copyWith(
            color: context.semantic.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SosBadge extends StatelessWidget {
  const _SosBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.semantic.sos,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.crisis_alert,
            color: context.semantic.textOnPrimary,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              color: context.semantic.textOnPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton loader ─────────────────────────────────────────────────────────

/// Animated shimmer skeleton that mirrors the shape of [_CommunityCard].
class CommunityCardSkeleton extends StatefulWidget {
  const CommunityCardSkeleton({super.key});

  @override
  State<CommunityCardSkeleton> createState() => _CommunityCardSkeletonState();
}

class _CommunityCardSkeletonState extends State<CommunityCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double width = double.infinity, double height = 14.0, double radius = 8}) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.semantic.borderStrong,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.semantic.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semantic.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          AnimatedBuilder(
            animation: _opacity,
            builder: (context, _) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.semantic.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: ~60% width
                LayoutBuilder(
                  builder: (ctx, bc) =>
                      _box(width: bc.maxWidth * 0.6, height: 15),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Subtitle line 1: ~80%
                LayoutBuilder(
                  builder: (ctx, bc) =>
                      _box(width: bc.maxWidth * 0.8, height: 12),
                ),
                const SizedBox(height: AppSpacing.xxs),
                // Subtitle line 2: ~40%
                LayoutBuilder(
                  builder: (ctx, bc) =>
                      _box(width: bc.maxWidth * 0.4, height: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Badge pill: 80px wide
                _box(width: 80, height: 22, radius: AppRadius.pill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
