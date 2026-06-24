import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/community_remote_data_source.dart';
import '../../models/community_search_result.dart';
import '../providers/communities_provider.dart';
import 'join_by_code_page.dart';

class CommunityDiscoverPage extends ConsumerStatefulWidget {
  const CommunityDiscoverPage({super.key});

  @override
  ConsumerState<CommunityDiscoverPage> createState() =>
      _CommunityDiscoverPageState();
}

class _CommunityDiscoverPageState extends ConsumerState<CommunityDiscoverPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int? _selectedType;
  String? _submittingCommunityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSearch();
      _loadNearby();
    });
  }

  Future<void> _loadNearby() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    await ref.read(communitiesProvider.notifier).loadNearbyCommunities(
          lat: position.latitude,
          lng: position.longitude,
        );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    ref.read(communitiesProvider.notifier).searchCommunities(
          nameQuery: _searchController.text,
          type: _selectedType,
        );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  void _onTypeSelected(int? type) {
    setState(() => _selectedType = type);
    _runSearch();
  }

  Future<void> _navigateToJoinByCode() async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JoinByCodePage()),
    );
    if (joined == true && mounted) _runSearch();
  }

  Future<void> _submitJoinRequest(String communityId) async {
    setState(() => _submittingCommunityId = communityId);
    final result =
        await ref.read(communitiesProvider.notifier).requestToJoin(communityId);
    if (!mounted) return;
    setState(() => _submittingCommunityId = null);

    if (result == null) {
      final err = ref.read(communitiesProvider).error;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err, textDirection: TextDirection.rtl)),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم إرسال طلب الانضمام — بانتظار موافقة المشرف',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communitiesProvider);
    final results = state.searchResults;
    final nearby = state.nearbyCommunities;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'اكتشف مجتمعات',
            subtitle: 'ابحث بالاسم أو نوع المجتمع',
            onBack: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المجتمع…',
                hintTextDirection: TextDirection.rtl,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: context.semantic.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _TypeChip(
                  label: 'الكل',
                  selected: _selectedType == null,
                  onTap: () => _onTypeSelected(null),
                ),
                const SizedBox(width: AppSpacing.xs),
                _TypeChip(
                  label: CommunityType.neighborhood.labelAr,
                  selected: _selectedType == 0,
                  onTap: () => _onTypeSelected(0),
                ),
                const SizedBox(width: AppSpacing.xs),
                _TypeChip(
                  label: CommunityType.building.labelAr,
                  selected: _selectedType == 1,
                  onTap: () => _onTypeSelected(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.isSearching && results.isEmpty && nearby.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty && nearby.isEmpty
                    ? const _EmptySearchState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          _runSearch();
                          await _loadNearby();
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenHorizontal,
                            AppSpacing.sm,
                            AppSpacing.screenHorizontal,
                            AppSpacing.xxl,
                          ),
                          children: [
                            if (nearby.isNotEmpty) ...[
                              Text(
                                'مجتمعات قريبة',
                                textDirection: TextDirection.rtl,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ...nearby.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _NearbyResultCard(
                                    item: item,
                                    onJoinByCode: _navigateToJoinByCode,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (results.isNotEmpty) ...[
                              Text(
                                'نتائج البحث',
                                textDirection: TextDirection.rtl,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ...results.map(
                                (community) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _SearchResultCard(
                                    community: community,
                                    action: _buildActionButton(community),
                                  ),
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

  Widget _buildActionButton(CommunitySearchResult community) {
    if (community.isAlreadyMember) {
      return Text(
        'عضو ✓',
        textDirection: TextDirection.rtl,
        style: context.text.labelMedium?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    switch (community.myJoinStatus) {
      case JoinStatus.pending:
        return Text(
          'الطلب قيد المراجعة…',
          textDirection: TextDirection.rtl,
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.warning,
            fontWeight: FontWeight.w600,
          ),
        );
      case JoinStatus.rejected:
        return Text(
          'تم رفض الطلب',
          textDirection: TextDirection.rtl,
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.error,
            fontWeight: FontWeight.w600,
          ),
        );
      case JoinStatus.banned:
        return Text(
          'محظور',
          textDirection: TextDirection.rtl,
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.error,
            fontWeight: FontWeight.w600,
          ),
        );
      default:
        if (community.acceptsJoinRequests) {
          final isSubmitting = _submittingCommunityId == community.id;
          return FilledButton(
            onPressed: isSubmitting
                ? null
                : () => _submitJoinRequest(community.id),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('طلب الانضمام'),
          );
        } else if (community.hasActiveInviteCode) {
          return FilledButton(
            onPressed: _navigateToJoinByCode,
            child: const Text('أدخل كود الدعوة'),
          );
        }
        return const SizedBox.shrink();
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, textDirection: TextDirection.rtl),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: context.colors.primary.withValues(alpha: 0.15),
      checkmarkColor: context.colors.primary,
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.community,
    required this.action,
  });

  final CommunitySearchResult community;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final type = CommunityType.fromValue(community.communityType);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      textDirection: TextDirection.rtl,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      type.labelAr,
                      textDirection: TextDirection.rtl,
                      style: context.text.labelSmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                    if (community.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        community.description!,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${community.memberCount} عضو',
                      textDirection: TextDirection.rtl,
                      style: context.text.labelSmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: action,
          ),
        ],
      ),
    );
  }
}

class _NearbyResultCard extends StatelessWidget {
  const _NearbyResultCard({
    required this.item,
    required this.onJoinByCode,
  });

  final NearbyCommunityDto item;
  final VoidCallback onJoinByCode;

  @override
  Widget build(BuildContext context) {
    final type = CommunityType.fromValue(item.communityType);
    final distanceKm = (item.distanceMeters / 1000).toStringAsFixed(1);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.name,
            textDirection: TextDirection.rtl,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${type.labelAr} • $distanceKm كم • ${item.memberCount} عضو',
            textDirection: TextDirection.rtl,
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.textMuted,
            ),
          ),
          if (type == CommunityType.neighborhood) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'اطلب الانضمام من نتائج البحث أعلاه',
                textDirection: TextDirection.rtl,
                style: context.text.labelSmall?.copyWith(
                  color: context.semantic.textMuted,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onJoinByCode,
                child: const Text('أدخل كود الدعوة'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: context.semantic.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد نتائج',
              textDirection: TextDirection.rtl,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'جرّب اسمًا مختلفًا أو غيّر نوع المجتمع',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
