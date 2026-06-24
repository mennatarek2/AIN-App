import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_page_header.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'المساعد الذكي',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AppEmptyView(
                    icon: Icons.smart_toy_outlined,
                    title: 'المساعد الذكي غير متاح حالياً',
                    subtitle:
                        'سيتم تفعيل هذه الميزة عند توفر واجهة برمجة التطبيقات',
                  ),
                  const Spacer(flex: 3),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      GestureDetector(
                        onTap: null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.4,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: context.semantic.textOnPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.semantic.surfaceHeader,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: TextField(
                            controller: _messageController,
                            enabled: false,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: context.text.bodyLarge?.copyWith(
                              color: context.colors.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            decoration: InputDecoration(
                              hintText: 'مراسلة...',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: context.text.bodyLarge?.copyWith(
                                color: context.semantic.textMuted.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
