import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../providers/home_feed_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_filter_row.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/report_card.dart';
import '../widgets/shimmer_report_card.dart';
import 'add_report_page.dart';
import 'your_location_page.dart';
import '../../../community/presentation/pages/community_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    // Trigger load more at 80% scroll depth
    if (current >= maxScroll * 0.80) {
      ref.read(publicFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavIndex = ref.watch(homeNavigationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildAppBar(isDark),
            // Location quick-access
            _buildLocationBar(isDark),
            // Category filter row
            const SizedBox(height: 12),
            const CategoryFilterRow(),
            const SizedBox(height: 8),
            // Feed
            Expanded(child: _buildFeed()),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedNavIndex,
          onReportTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddReportPage()),
            );
          },
          onTap: (index) {
            if (index == 2) return; // handled by onReportTap
            ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
            _navigateToTab(index);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1230) : AppColors.primarySoft,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Title
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _searchVisible
                  ? TextField(
                      key: const ValueKey('search-field'),
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      autofocus: true,
                      onChanged: (v) {
                        ref
                            .read(publicFeedProvider.notifier)
                            .setSearch(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في البلاغات...',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 15,
                      ),
                    )
                  : Text(
                      'الرئيسية',
                      key: const ValueKey('home-title'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
            ),
          ),
          // Search toggle
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.close_rounded : Icons.search_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            onPressed: () {
              setState(() => _searchVisible = !_searchVisible);
              if (!_searchVisible) {
                _searchController.clear();
                ref.read(publicFeedProvider.notifier).setSearch('');
              }
            },
          ),
          // Filter
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            onPressed: () => showFilterBottomSheet(context),
          ),
          // Notifications bell with live unread badge
          _NotificationBell(isDark: isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Location bar
  // ---------------------------------------------------------------------------
  Widget _buildLocationBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const YourLocationPage()),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(
                alpha: isDark ? 0.18 : 0.30,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                const SizedBox(width: 5),
                Text(
                  'موقعك الحالي',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feed
  // ---------------------------------------------------------------------------
  Widget _buildFeed() {
    final feedAsync = ref.watch(publicFeedProvider);

    return feedAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: 5,
        itemBuilder: (context, index) => const ShimmerReportCard(),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'تعذّر تحميل البلاغات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    ref.read(publicFeedProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (feedState) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(publicFeedProvider.notifier).refresh(),
        child: feedState.reports.isEmpty && !feedState.isRefreshing
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.only(top: 4, bottom: 100),
                itemCount:
                    feedState.reports.length +
                    (feedState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == feedState.reports.length) {
                    // Load-more spinner
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  final report = feedState.reports[index];
                  return _buildReportCard(report);
                },
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Report card
  // ---------------------------------------------------------------------------
  Widget _buildReportCard(ReportModel report) {
    final tags = <ReportTag>[
      if (report.categoryName != null && report.categoryName!.isNotEmpty)
        ReportTag(
          label: report.categoryName!,
          dotColor: AppColors.primary,
          showDot: false,
        ),
      if (report.subCategoryName != null &&
          report.subCategoryName!.isNotEmpty)
        ReportTag(
          label: report.subCategoryName!,
          dotColor: const Color(0xFF6366F1),
          showDot: false,
        ),
      ReportTag(
        label: report.statusLabel,
        dotColor: report.statusColor,
      ),
    ];

    final vis = report.visibility?.toLowerCase();
    final reporterName = report.reporter?.name ?? report.createdByName;
    final username = () {
      if (vis == 'anonymous') return 'مجهول';
      if (reporterName != null && reporterName.trim().isNotEmpty) {
        return reporterName.trim();
      }
      return '';
    }();

    final imageUrls = report.imageUrls;
    final primaryImage = imageUrls.isNotEmpty
        ? imageUrls.first
        : report.imagePath;

    return ReportCard(
      username: username,
      reporterAvatarUrl: report.reporter?.resolvedPhotoUrl,
      timeAgo: report.submittedAgo,
      title: report.title,
      description: report.description,
      imageUrl: primaryImage,
      imageUrls: imageUrls,
      tags: tags,
      attachmentCount: report.attachments.length,
      locationPreview: report.displayLocation,
      locationMapUrl: report.mapsUrl,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportDetailPage(reportId: report.id),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(publicFeedProvider).valueOrNull;
    final hasFilter = feedState?.filter.categoryId != null ||
        feedState?.filter.status != null ||
        (feedState?.filter.search?.isNotEmpty ?? false);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFilter
                      ? Icons.filter_list_off_rounded
                      : Icons.inbox_rounded,
                  size: 72,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  hasFilter
                      ? 'لا توجد بلاغات تطابق الفلتر'
                      : 'لا توجد بلاغات حالياً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (hasFilter)
                  TextButton(
                    onPressed: () => ref
                        .read(publicFeedProvider.notifier)
                        .applyFilter(const FeedFilter()),
                    child: const Text(
                      'مسح الفلاتر',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab navigation
  // ---------------------------------------------------------------------------
  void _navigateToTab(int index) {
    switch (index) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommunityPage()),
        );
      case 3:
        Navigator.of(context).pushNamed(AppRoutes.sos);
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      default:
        break;
    }
  }
}

// ─── Notification bell with live badge ───────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            unread > 0
                ? Icons.notifications_rounded
                : Icons.notifications_outlined,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pushNamed('/notifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
