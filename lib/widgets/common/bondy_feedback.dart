import 'package:flutter/material.dart';

import '../../core/bondy_error_mapper.dart';
import '../../screens/healing/healing_stitch_style.dart';

/// Snackbar / banner / empty state theo phong cách Healing.
class BondyFeedback {
  BondyFeedback._();

  static void showError(BuildContext context, Object? error, {String? fallback}) {
    final text = fallback ?? BondyErrorMapper.message(error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, style: healingText(size: 14, color: Colors.white)),
          backgroundColor: HealingStitchColors.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: healingText(size: 14, color: Colors.white)),
          backgroundColor: const Color(0xFF2E9E6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

class BondyErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const BondyErrorBanner({super.key, required this.message, this.onRetry});

  factory BondyErrorBanner.fromError(Object? error, {VoidCallback? onRetry}) {
    return BondyErrorBanner(
      message: BondyErrorMapper.message(error),
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealingStitchColors.paleCoral,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealingStitchColors.coral.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: HealingStitchColors.coral, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: healingText(
                    size: 14,
                    weight: FontWeight.w600,
                    color: HealingStitchColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: Text(
                  'Thử lại',
                  style: healingText(
                    weight: FontWeight.w700,
                    color: HealingStitchColors.coral,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BondyLoadingState extends StatelessWidget {
  final String? label;

  const BondyLoadingState({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: HealingStitchColors.coral),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(
              label!,
              style: healingText(color: HealingStitchColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class BondyEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BondyEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: healingText(size: 18, weight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: healingText(color: HealingStitchColors.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            HealingGradientButton(label: actionLabel!, onTap: onAction),
          ],
        ],
      ),
    );
  }
}

/// Ô hiển thị lỗi trong form (auth, survey...).
class BondyInlineError extends StatelessWidget {
  final String? message;

  const BondyInlineError({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: BondyErrorBanner(message: message!),
    );
  }
}
