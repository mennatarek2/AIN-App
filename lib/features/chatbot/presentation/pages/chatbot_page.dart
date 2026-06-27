import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/chatbot_provider.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _focusNode.requestFocus();
    await ref.read(chatbotProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatbotProvider);

    ref.listen<ChatbotState>(chatbotProvider, (previous, next) {
      if (next.messages.length != (previous?.messages.length ?? 0) ||
          next.isSending != (previous?.isSending ?? false)) {
        _scrollToBottom();
      }
    });

    final canSend =
        !chatState.isSending && _messageController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          AppPageHeader(
            title: 'المساعد الذكي',
            subtitle: 'اسأل عن البلاغات والمجتمع والتطبيق',
            onBack: () => Navigator.of(context).pop(),
            actions: [
              if (chatState.messages.isNotEmpty)
                IconButton(
                  tooltip: 'محادثة جديدة',
                  onPressed: chatState.isSending
                      ? null
                      : () => ref.read(chatbotProvider.notifier).clearConversation(),
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: context.semantic.textOnPrimary,
                  ),
                ),
            ],
          ),
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isSending
                ? _WelcomeView(onSuggestionTap: _sendSuggestion)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                    ),
                    itemCount:
                        chatState.messages.length + (chatState.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= chatState.messages.length) {
                        return const _TypingIndicatorBubble();
                      }
                      final message = chatState.messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
          ),
          _ChatInputBar(
            controller: _messageController,
            focusNode: _focusNode,
            isSending: chatState.isSending,
            canSend: canSend,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendSuggestion(String text) {
    _messageController.text = text;
    _sendMessage();
  }
}

// ─── Welcome / empty state ────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onSuggestionTap});

  final void Function(String text) onSuggestionTap;

  static const _suggestions = [
    'كيف أُقدّم بلاغاً جديداً؟',
    'ما هي حالات البلاغ؟',
    'كيف أنضم إلى مجتمع؟',
    'كيف أستخدم نداء الطوارئ SOS؟',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: context.headerGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 40,
              color: context.semantic.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'مرحباً! أنا مساعد عين الذكي',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'يمكنني مساعدتك في فهم كيفية استخدام التطبيق، البلاغات، المجتمعات، ونداءات الطوارئ.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'اقتراحات للبدء',
              textDirection: TextDirection.rtl,
              style: context.text.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: _suggestions.map((text) {
              return ActionChip(
                label: Text(
                  text,
                  textDirection: TextDirection.rtl,
                ),
                onPressed: () => onSuggestionTap(text),
                backgroundColor: context.semantic.surfaceContainer,
                side: BorderSide(color: context.semantic.borderSubtle),
                labelStyle: context.text.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    final bubbleColor = isError
        ? context.semantic.error.withValues(alpha: 0.1)
        : isUser
        ? context.colors.primary
        : context.semantic.surfaceContainer;

    final textColor = isError
        ? context.semantic.error
        : isUser
        ? context.semantic.textOnPrimary
        : context.colors.onSurface;

    final borderColor = isError
        ? context.semantic.error.withValues(alpha: 0.35)
        : isUser
        ? Colors.transparent
        : context.semantic.borderSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(isUser: false, isError: isError),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.lg),
                      topRight: const Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(
                        isUser ? AppRadius.xs : AppRadius.lg,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? AppRadius.lg : AppRadius.xs,
                      ),
                    ),
                    border: Border.all(color: borderColor),
                    boxShadow: isUser
                        ? [
                            BoxShadow(
                              color: context.colors.primary.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : context.cardShadows,
                  ),
                  child: Text(
                    message.content,
                    textDirection: TextDirection.rtl,
                    style: context.text.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _formatTime(message.createdAt),
                  textDirection: TextDirection.rtl,
                  style: context.text.labelSmall?.copyWith(
                    color: context.semantic.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.xs),
            const _Avatar(isUser: true, isError: false),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser, required this.isError});

  final bool isUser;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? context.colors.primary.withValues(alpha: 0.15)
            : isError
            ? context.semantic.error.withValues(alpha: 0.12)
            : context.semantic.surfaceHeader,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser
              ? context.colors.primary.withValues(alpha: 0.3)
              : context.semantic.borderSubtle,
        ),
      ),
      child: Icon(
        isUser
            ? Icons.person_rounded
            : isError
            ? Icons.error_outline_rounded
            : Icons.smart_toy_rounded,
        size: 18,
        color: isUser
            ? context.colors.primary
            : isError
            ? context.semantic.error
            : context.colors.primary,
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const _Avatar(isUser: false, isError: false),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.semantic.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.xs),
              ),
              border: Border.all(color: context.semantic.borderSubtle),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay).clamp(0.0, 1.0);
                    final scale = 0.5 + (Curves.easeInOut.transform(value) * 0.5);
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index < 2 ? AppSpacing.xxs : 0,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.5 + (scale * 0.5),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        bottomInset + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.semantic.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: context.semantic.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SendButton(
            canSend: canSend,
            isSending: isSending,
            onSend: onSend,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: context.semantic.surfaceHeader,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: context.semantic.borderSubtle),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isSending,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 4,
                minLines: 1,
                onSubmitted: isSending ? null : (_) => onSend(),
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: context.text.bodyLarge?.copyWith(
                    color: context.semantic.textMuted.withValues(alpha: 0.7),
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
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canSend ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: canSend ? context.headerGradient : null,
          color: canSend
              ? null
              : context.colors.primary.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isSending
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.semantic.textOnPrimary,
                ),
              )
            : Icon(
                Icons.send_rounded,
                color: context.semantic.textOnPrimary,
                size: 22,
              ),
      ),
    );
  }
}
