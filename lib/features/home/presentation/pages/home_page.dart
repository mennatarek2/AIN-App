import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_premium_location_card.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../reports/domain/report_model.dart';
import '../../../reports/presentation/pages/report_detail_page.dart';
import '../providers/home_feed_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/report_card.dart';
import '../widgets/shimmer_report_card.dart';
import 'add_report_page.dart';
import 'your_location_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
    if (current >= maxScroll * 0.80) {
      ref.read(publicFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavIndex = ref.watch(homeNavigationProvider);
    final feedState = ref.watch(publicFeedProvider).valueOrNull;
    final hasActiveFilter =
        feedState?.filter.categoryId != null ||
        feedState?.filter.status != null ||
        (feedState?.filter.search?.isNotEmpty ?? false);

    final body = _buildScrollableBody(hasActiveFilter);

    if (widget.embeddedInShell) {
      return body;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: body,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedNavIndex,
          onReportTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddReportPage()),
            );
          },
          onTap: (index) {
            if (index == 2) return;
            if (index == 0) return;
            ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
            navigateFromBottomNav(context, ref, index);
          },
        ),
      ),
    );
  }

  Widget _buildScrollableBody(bool hasActiveFilter) {
    final feedAsync = ref.watch(publicFeedProvider);

    return feedAsync.when(
      loading: () => CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._buildHeaderSlivers(hasActiveFilter),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const ShimmerReportCard(),
              childCount: 5,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      error: (_, __) => CustomScrollView(
        controller: _scrollController,
        slivers: [
          ..._buildHeaderSlivers(hasActiveFilter),
          SliverFillRemaining(
            child: AppErrorView(
              message: 'تعذّر تحميل البلاغات',
              onRetry: () => ref.read(publicFeedProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
      data: (feedState) => RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () => ref.read(publicFeedProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ..._buildHeaderSlivers(hasActiveFilter),
            if (feedState.reports.isEmpty && !feedState.isRefreshing)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyStateContent(hasActiveFilter),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == feedState.reports.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.colors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    return _buildReportCard(feedState.reports[index]);
                  },
                  childCount:
                      feedState.reports.length +
                      (feedState.isLoadingMore ? 1 : 0),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeaderSlivers(bool hasActiveFilter) {
    return [
      SliverToBoxAdapter(
        child: AppDashboardHeader(
          title: 'عين',
          subtitle: 'منصة البلاغات والمساعدة المجتمعية',
          searchHint: 'ابحث في البلاغات...',
          searchController: _searchController,
          onSearchChanged: (v) =>
              ref.read(publicFeedProvider.notifier).setSearch(v),
          trailing: [
            _NotificationBell(),
            IconButton(
              onPressed: () => showFilterBottomSheet(context),
              icon: Icon(
                Icons.tune_rounded,
                color: context.semantic.textOnPrimary,
              ),
              tooltip: 'تصفية',
            ),
          ],
        ),
      ),
      SliverToBoxAdapter(
        child: AppPremiumLocationCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const YourLocationPage()),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: AppSectionHeader(
          title: 'آخر البلاغات',
          actionLabel: hasActiveFilter ? 'مسح الفلاتر' : null,
          onAction: hasActiveFilter
              ? () => ref
                    .read(publicFeedProvider.notifier)
                    .applyFilter(const FeedFilter())
              : null,
        ),
      ),
    ];
  }

  Widget _buildEmptyStateContent(bool hasActiveFilter) {
    return AppEmptyView(
      icon: hasActiveFilter
          ? Icons.filter_list_off_rounded
          : Icons.article_outlined,
      title: hasActiveFilter
          ? 'لا توجد بلاغات تطابق الفلتر'
          : 'لا توجد بلاغات حالياً',
      subtitle: hasActiveFilter
          ? 'جرّب تعديل معايير البحث أو مسح الفلاتر'
          : 'كن أول من يبلّغ عن حالة في منطقتك',
      actionLabel: hasActiveFilter ? 'مسح الفلاتر' : 'إنشاء بلاغ',
      onAction: hasActiveFilter
          ? () => ref
                .read(publicFeedProvider.notifier)
                .applyFilter(const FeedFilter())
          : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddReportPage()),
            ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final tags = <ReportTag>[
      if (report.categoryName != null && report.categoryName!.isNotEmpty)
        ReportTag(
          label: report.categoryName!,
          dotColor: context.colors.primary,
          showDot: false,
        ),
      if (report.subCategoryName != null && report.subCategoryName!.isNotEmpty)
        ReportTag(
          label: report.subCategoryName!,
          dotColor: context.colors.secondary,
          showDot: false,
        ),
      ReportTag(label: report.statusLabel, dotColor: report.statusColor),
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
    final primaryImage =
        imageUrls.isNotEmpty ? imageUrls.first : report.imagePath;

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
      statusColor: report.statusColor,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportDetailPage(reportId: report.id),
          ),
        );
      },
    );
  }
}

class _NotificationBell extends ConsumerWidget {
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
            color: context.semantic.textOnPrimary,
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
                color: context.semantic.sos,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.semantic.textOnPrimary,
                  width: 1.2,
                ),
              ),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: TextStyle(
                  fontSize: 9,
                  color: context.semantic.textOnPrimary,
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
