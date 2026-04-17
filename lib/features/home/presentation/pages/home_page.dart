import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../providers/home_feed_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/report_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'add_report_page.dart';
import 'your_location_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final selectedNavIndex = ref.watch(homeNavigationProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Location button
                  _buildLocationBar(),
                  // Latest reports title
                  _buildSectionTitle(),
                  // Search bar with filter
                  _buildSearchBar(),
                  // Reports feed
                  ..._buildReportsList(),
                  const SizedBox(height: 100), // Space for FAB and nav bar
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedNavIndex,
          onTap: (index) {
            ref.read(homeNavigationProvider.notifier).setSelectedIndex(index);
            if (index == 0) {
              return;
            }
            navigateFromBottomNav(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      alignment: Alignment.bottomCenter,
      color: isDark ? const Color(0xFF121A5C) : AppColors.primarySoft,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // User avatar button (clickable to profile)
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isDark ? const Color(0xFFC4CCDB) : Colors.white,
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting text
          Expanded(
            child: Text(
              'أهلاً بك',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const YourLocationPage()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(
                alpha: isDark ? 0.2 : 0.35,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'موقعك',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
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

  Widget _buildSectionTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'أحدث البلاغات',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(homeFeedProvider);
    final fieldTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final hintColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final fieldBorderColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Search field
          Expanded(
            child: TextField(
              onChanged: (value) {
                ref.read(homeFeedProvider.notifier).setSearchQuery(value);
              },
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'البحث',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(color: hintColor, fontSize: 17),
                suffixIcon: Icon(Icons.search, color: fieldTextColor, size: 30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppColors.backgroundDark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: 1.5708,
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              iconSize: 24,
              color: fieldTextColor,
              onPressed: () {
                ref.read(homeFeedProvider.notifier).toggleFilter();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      feedState.filterEnabled
                          ? 'تم إيقاف الفلترة'
                          : 'تم تفعيل الفلترة',
                    ),
                  ),
                );
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReportsList() {
    final reports = ref.watch(filteredHomeReportsProvider);
    final commentsByReport = ref.watch(homeFeedProvider).commentsByReport;

    return reports
        .map(
          (report) => ReportCard(
            username: report.username,
            timeAgo: report.timeAgo,
            title: report.title,
            imageUrl: report.imageUrl,
            tags: report.tags,
            commentCount: commentsByReport[report.id]?.length ?? 0,
            onLike: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Liked!')));
            },
            onComment: () {
              _openCommentsSheet(report);
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share not yet implemented')),
              );
            },
          ),
        )
        .toList();
  }

  void _openCommentsSheet(HomeReport report) {
    final reportId = report.id;
    final comments = ref
        .read(homeFeedProvider.notifier)
        .commentsForReport(reportId);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          comments: comments,
          onLikeComment: (commentId) {
            ref.read(homeFeedProvider.notifier).toggleLike(reportId, commentId);
          },
          onSendComment: (text) {
            ref.read(homeFeedProvider.notifier).addComment(reportId, text);
          },
        );
      },
    );
  }

  Widget _buildFAB() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddReportPage()));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 12),
        height: 60,
        width: 112,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121A5C) : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'إضافة بلاغ',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 21,
            ),
          ),
        ),
      ),
    );
  }
}
