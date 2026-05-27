import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ai/ai_coach_viewmodel.dart';

class AiSuggestionBottomSheet extends StatelessWidget {
  final VoidCallback onDismiss;
  final ValueChanged<String> onSuggestionSelected;

  const AiSuggestionBottomSheet({
    super.key,
    required this.onDismiss,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiCoachViewModel(),
      child: _AiSuggestionBottomSheetContent(
        onDismiss: onDismiss,
        onSuggestionSelected: onSuggestionSelected,
      ),
    );
  }
}

class _AiSuggestionBottomSheetContent extends StatelessWidget {
  final VoidCallback onDismiss;
  final ValueChanged<String> onSuggestionSelected;

  const _AiSuggestionBottomSheetContent({
    required this.onDismiss,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AiCoachViewModel>();

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BondyColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              const Text('✨ ', style: TextStyle(fontSize: 22)),
              Text(
                'AI Gợi ý',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                  letterSpacing: -0.02,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: BondyColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Intent selector
          if (viewModel.suggestions.isEmpty && !viewModel.isLoading) ...[
            _buildIntentSelector(context, viewModel),
          ] else ...[
            _buildContent(context, viewModel),
          ],
        ],
      ),
    );
  }

  Widget _buildIntentSelector(BuildContext context, AiCoachViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn muốn nói gì?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AiIntent.values.map((intent) {
            final isSelected = intent == viewModel.selectedIntent;
            return GestureDetector(
              onTap: () => viewModel.selectIntent(intent),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? BondyColors.signatureGradient : null,
                  color: isSelected ? null : BondyColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(BondyRadius.full),
                  border: isSelected
                      ? null
                      : Border.all(color: BondyColors.ghostBorder),
                ),
                child: Text(
                  intent.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : BondyColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Get suggestions button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => viewModel.getSuggestions(
              conversationId: 'mock-conversation',
              userId: 'mock-user',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BondyColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BondyRadius.md),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Nhận gợi ý',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AiCoachViewModel viewModel) {
    if (viewModel.isLoading) {
      return _buildLoadingState();
    }

    if (viewModel.isLimitReached) {
      return _buildLimitReachedContent(context);
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorContent(context, viewModel);
    }

    return _buildSuggestionsList(context, viewModel);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(BondyColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tạo gợi ý...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: BondyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitReachedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Bạn đã hết lượt gợi ý hôm nay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: BondyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nâng cấp để nhận gợi ý không giới hạn từ AI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: BondyColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: BondyColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BondyRadius.md),
              ),
            ),
            child: const Text('Nâng cấp ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, AiCoachViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('😔', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            viewModel.errorMessage!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: BondyColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => viewModel.getSuggestions(
              conversationId: 'mock-conversation',
              userId: 'mock-user',
            ),
            child: Text(
              'Thử lại',
              style: GoogleFonts.plusJakartaSans(
                color: BondyColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, AiCoachViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Chọn gợi ý phù hợp:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: BondyColors.textSecondary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => viewModel.reset(),
              child: Text(
                '← Thay đổi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: BondyColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...viewModel.suggestions.map((s) => _SuggestionChip(
              suggestion: s,
              onTap: () => onSuggestionSelected(s),
            )),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BondyRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BondyColors.surface,
              borderRadius: BorderRadius.circular(BondyRadius.md),
              border: Border.all(color: BondyColors.ghostBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BondyColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: BondyColors.signatureGradient,
                    borderRadius: BorderRadius.circular(BondyRadius.sm),
                  ),
                  child: const Icon(
                    Icons.north_west,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}