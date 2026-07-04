import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../viewmodels/ai/ai_quota_viewmodel.dart';

Future<void> showAiQuotaPaywallDialog(
  BuildContext context, {
  AiQuotaExceededData? data,
  AiModeQuota? quota,
  String? fallbackMessage,
}) async {
  final paywall = data?.paywall;
  final modal = data?.upgradeModal;
  final title = paywall?.title ?? modal?.title ?? 'Bạn đã hết lượt AI hôm nay';
  final message =
      paywall?.message ??
      modal?.message ??
      fallbackMessage ??
      'Mua thêm lượt AI hoặc nâng cấp subscription để tiếp tục trò chuyện.';
  final ctaLabel = paywall?.primaryCtaLabel ?? modal?.ctaLabel ?? 'Xem gói AI';
  final tab = paywall?.redirectTab ?? 'aiChatPasses';
  final currentQuota = quota ?? data?.quota;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title),
      content: Text(
        currentQuota == null
            ? message
            : '$message\n\nHiện tại: ${currentQuota.remaining}/${currentQuota.limit} lượt.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(modal?.secondaryCtaLabel ?? 'Để sau'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await Navigator.of(
              context,
            ).pushNamed('/settings/premium', arguments: {'initialTab': tab});
            if (!context.mounted) return;
            try {
              await context.read<AiQuotaViewModel>().loadQuota();
            } catch (_) {}
          },
          child: Text(ctaLabel),
        ),
      ],
    ),
  );
}
