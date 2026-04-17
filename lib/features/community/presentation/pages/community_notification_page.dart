import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CommunityNotificationItem {
  const CommunityNotificationItem({
    required this.title,
    required this.timeAgo,
    required this.titleColor,
  });

  final String title;
  final String timeAgo;
  final Color titleColor;
}

class CommunityNotificationPage extends StatelessWidget {
  const CommunityNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060C3A)
          : AppColors.backgroundLight,
      body: Column(
        children: [
          _Header(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return _NotificationCard(item: item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _notifications.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
                'تنبيهات الدائرة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 21,
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final CommunityNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060C3A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFFF3F6F9) : const Color(0x66060C3A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: item.titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• ${item.timeAgo}',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFF3F6F9) : const Color(0x66060C3A),
            ),
          ),
        ],
      ),
    );
  }
}

const List<CommunityNotificationItem> _notifications = [
  CommunityNotificationItem(
    title: 'حادث بالقرب من Laila',
    timeAgo: 'منذ 3 دقائق',
    titleColor: Color(0xFFD9D9D9),
  ),
  CommunityNotificationItem(
    title: 'المنطقة المحيطة بـ Khaled مستقرة',
    timeAgo: 'منذ 4 دقائق',
    titleColor: Color(0xFF2E8B57),
  ),
  CommunityNotificationItem(
    title: 'اندلاع حريق بالقرب من Youssef',
    timeAgo: 'منذ 15 دقيقة',
    titleColor: Color(0xFFD23B3B),
  ),
];
