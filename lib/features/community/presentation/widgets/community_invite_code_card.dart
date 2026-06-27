import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../providers/communities_provider.dart';
import 'community_dialogs.dart';

/// Invite code display with copy, regenerate, and revoke actions.
class CommunityInviteCodeCard extends ConsumerStatefulWidget {
  const CommunityInviteCodeCard({
    super.key,
    required this.communityId,
    required this.inviteCode,
    required this.canManageCodes,
  });

  final String communityId;
  final String? inviteCode;
  final bool canManageCodes;

  @override
  ConsumerState<CommunityInviteCodeCard> createState() =>
      _CommunityInviteCodeCardState();
}

class _CommunityInviteCodeCardState
    extends ConsumerState<CommunityInviteCodeCard> {
  String? _displayCode;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _displayCode = widget.inviteCode;
  }

  @override
  void didUpdateWidget(covariant CommunityInviteCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inviteCode != widget.inviteCode) {
      _displayCode = widget.inviteCode;
    }
  }

  Future<void> _regenerate() async {
    if (widget.canManageCodes &&
        _displayCode != null &&
        _displayCode!.isNotEmpty) {
      if (!await CommunityDialogs.confirmRegenerateInviteCode(context)) {
        return;
      }
    }

    setState(() => _isBusy = true);
    final result = await ref
        .read(communitiesProvider.notifier)
        .regenerateInviteCode(widget.communityId);
    if (mounted) setState(() => _isBusy = false);
    if (!mounted) return;

    if (result != null) {
      setState(() => _displayCode = result.inviteCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إنشاء كود دعوة جديد',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    } else {
      final error = ref.read(communitiesProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
        );
      }
    }
  }

  Future<void> _revoke() async {
    if (!await CommunityDialogs.confirmRevokeInviteCode(context)) return;

    setState(() => _isBusy = true);
    final error = await ref
        .read(communitiesProvider.notifier)
        .revokeInviteCode(widget.communityId);
    if (mounted) setState(() => _isBusy = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, textDirection: TextDirection.rtl)),
      );
      return;
    }
    setState(() => _displayCode = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إلغاء كود الدعوة', textDirection: TextDirection.rtl),
      ),
    );
  }

  Future<void> _copyCode() async {
    final code = _displayCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كود الدعوة', textDirection: TextDirection.rtl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'كود الدعوة',
            textDirection: TextDirection.rtl,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_displayCode != null && _displayCode!.isNotEmpty)
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'نسخ',
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
                Expanded(
                  child: SelectableText(
                    _displayCode!,
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'لا يوجد كود دعوة نشط',
              textDirection: TextDirection.rtl,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.textMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.canManageCodes) ...[
            if (_isBusy)
              const Center(child: CircularProgressIndicator())
            else if (_displayCode == null || _displayCode!.isEmpty)
              OutlinedButton.icon(
                onPressed: _regenerate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إنشاء كود'),
              )
            else
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _regenerate,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة التوليد'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _revoke,
                      icon: Icon(
                        Icons.block_rounded,
                        size: 18,
                        color: context.semantic.error,
                      ),
                      label: Text(
                        'إلغاء',
                        style: TextStyle(color: context.semantic.error),
                      ),
                    ),
                  ),
                ],
              ),
          ] else if (_displayCode != null && _displayCode!.isNotEmpty)
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ الكود'),
              ),
            ),
        ],
      ),
    );
  }
}
