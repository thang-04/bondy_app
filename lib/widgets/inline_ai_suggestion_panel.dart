import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../viewmodels/ai/ai_coach_viewmodel.dart';

class InlineAiSuggestionPanel extends StatelessWidget {
  final AiCoachViewModel viewModel;
  final String partnerName;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onGenerate;
  final ValueChanged<AiIntent> onIntentSelected;
  final ValueChanged<String> onSuggestionSelected;

  const InlineAiSuggestionPanel({
    super.key,
    required this.viewModel,
    required this.partnerName,
    required this.onClose,
    required this.onRetry,
    required this.onGenerate,
    required this.onIntentSelected,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inline_ai_suggestion_panel'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BondyColors.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: BondyColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildIntentSelector(),
          const SizedBox(height: 10),
          _buildGenerateButton(),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final quota = viewModel.quota;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: BondyColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.auto_awesome,
                size: 20,
                color: BondyColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI gợi ý cho $partnerName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              Text(
                'Chọn một câu để đưa vào ô nhắn tin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: BondyColors.textSecondary,
                ),
              ),
              if (quota != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: quota.remaining <= 0
                        ? BondyColors.primary.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: BondyColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'Còn ${quota.remaining}/${quota.limit} lượt',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: quota.remaining <= 0
                          ? BondyColors.primaryDark
                          : BondyColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          key: const Key('close_ai_suggestion_panel'),
          tooltip: 'Đóng gợi ý AI',
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }

  Widget _buildIntentSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AiIntent.values.map((intent) {
          final isSelected = intent == viewModel.selectedIntent;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: Key('ai_intent_${intent.chatValue}'),
              label: Text(intent.label),
              selected: isSelected,
              onSelected: viewModel.isLoading
                  ? null
                  : (_) => onIntentSelected(intent),
              selectedColor: BondyColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? BondyColors.primary
                    : BondyColors.primary.withValues(alpha: 0.18),
              ),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : BondyColors.textPrimary,
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate =
        viewModel.selectedIntent != null && !viewModel.isLoading;
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        key: const Key('generate_ai_suggestions'),
        onPressed: canGenerate ? onGenerate : null,
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: const Text('Tạo gợi ý'),
        style: ElevatedButton.styleFrom(
          backgroundColor: BondyColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BondyColors.primary.withValues(alpha: 0.12),
          disabledForegroundColor: BondyColors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (viewModel.isLoading) {
      return SizedBox(
        key: const Key('ai_suggestion_loading'),
        height: 76,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                viewModel.loadingMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: BondyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.errorMessage != null || viewModel.isLimitReached) {
      return Container(
        key: const Key('ai_suggestion_error'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              size: 18,
              color: BondyColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                viewModel.isLimitReached
                    ? 'Bạn đã hết lượt gợi ý hôm nay.'
                    : viewModel.errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: BondyColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              key: const Key('retry_ai_suggestion'),
              onPressed: viewModel.selectedIntent == null ? null : onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (viewModel.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      key: const Key('ai_suggestion_list'),
      constraints: const BoxConstraints(maxHeight: 210),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: viewModel.suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final suggestion = viewModel.suggestions[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: Key('ai_suggestion_$index'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSuggestionSelected(suggestion),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        suggestion,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.35,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.call_made_rounded,
                      size: 17,
                      color: BondyColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
