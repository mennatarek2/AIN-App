import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/social_providers.dart';

class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل دخولك للإعجاب بالبلاغ'),
          backgroundColor: context.semantic.error,
        ),
      );
      return;
    }

    await _scaleController.forward(from: 0);
    await ref.read(reportLikeNotifierProvider(widget.reportId).notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    final likeAsync = ref.watch(reportLikeNotifierProvider(widget.reportId));
    final totalLikes = likeAsync.valueOrNull?.totalLikes ?? 0;
    final isLiked = likeAsync.valueOrNull?.isLikedByCaller ?? false;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          IconButton(
            onPressed: _onTap,
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked
                  ? context.semantic.error
                  : context.semantic.textMuted,
            ),
          ),
          Text(
            '$totalLikes',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
