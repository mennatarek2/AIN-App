import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_layout_primitives.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_views.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDarkMode = settings.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'الإعدادات',
            subtitle: 'خصّص تجربة التطبيق حسب تفضيلاتك',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              children: [
                AppSettingsSection(
                  title: 'المظهر',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'اختر وضع العرض',
                            textDirection: TextDirection.rtl,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppThemePreviewSelector(
                            isDarkMode: isDarkMode,
                            onChanged: (dark) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setDarkModeEnabled(dark);
                            },
                          ),
                        ],
                      ),
                    ),
                    AppSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      label: 'الوضع الداكن',
                      subtitle: isDarkMode
                          ? 'مفعّل — مريح للعين ليلاً'
                          : 'غير مفعّل',
                      showChevron: false,
                      trailing: AppThemeModeToggle(
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .setDarkModeEnabled(value);
                        },
                      ),
                    ),
                    AppSettingsTile(
                      icon: Icons.palette_outlined,
                      label: 'تخصيص الألوان',
                      subtitle: 'قريباً — اختر لون التطبيق المفضل',
                      showChevron: false,
                      trailing: const AppComingSoonBadge(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تخصيص الألوان سيتوفر في تحديث قادم',
                              textDirection: TextDirection.rtl,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppSettingsSection(
                  title: 'حول التطبيق',
                  children: [
                    AppSettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'عن عين',
                      subtitle: 'منصة البلاغات والمساعدة الطارئة للمواطنين',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'عين',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2026 Ai-N',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
