import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ai/ai_coach_viewmodel.dart';

class AiSuggestBottomSheet extends StatelessWidget {
  final List<String> suggestions;
  final bool isLoading;
  final String? errorMessage;
  final bool isLimitReached;
  final VoidCallback onDismiss;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback? onRetry;
  final VoidCallback? onPaywall;

  const AiSuggestBottomSheet({
    super.key,
    required this.suggestions,
    required this.isLoading,
    this.errorMessage,
    this.isLimitReached = false,
    required this.onDismiss,
    required this.onSuggestionSelected,
    this.onRetry,
    this.onPaywall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BondyColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 20)),
                Text(
                  'Gợi ý từ AI Coach',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            if (isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (isLimitReached) ...[
              _buildLimitReachedContent(context),
            ] else if (errorMessage != null) ...[
              _buildErrorContent(context),
            ] else ...[
              _buildSuggestionsList(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitReachedContent(BuildContext context) {
    return Column(
      children: [
        const Text('🔒', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          'Bạn đã hết lượt gợi ý hôm nay',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nâng cấp để tiếp tục nhận gợi ý không giới hạn từ AI Coach',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onPaywall,
          style: ElevatedButton.styleFrom(
            backgroundColor: BondyColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Nâng cấp ngay'),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      children: [
        const Text('😔', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          errorMessage!,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn gợi ý phù hợp với bạn:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((s) => _buildSuggestionChip(context, s)),
      ],
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSuggestionSelected(suggestion),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BondyColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BondyColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  suggestion,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                ),
              ),
              const Icon(Icons.send, size: 16, color: BondyColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// Intent selector for initial bottom sheet trigger
class AiIntentSelector extends StatelessWidget {
  final AiIntent selectedIntent;
  final ValueChanged<AiIntent> onIntentSelected;
  final VoidCallback onGetSuggestions;

  const AiIntentSelector({
    super.key,
    required this.selectedIntent,
    required this.onIntentSelected,
    required this.onGetSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Intent chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AiIntent.values.map((intent) {
              final isSelected = intent == selectedIntent;
              return FilterChip(
                label: Text(intent.label),
                selected: isSelected,
                onSelected: (_) => onIntentSelected(intent),
                selectedColor: BondyColors.primaryLight,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Get suggestions button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGetSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: BondyColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Nhận gợi ý'),
            ),
          ),
        ],
      ),
    );
  }
}
