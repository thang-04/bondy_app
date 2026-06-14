import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/bondy_error_mapper.dart';
import '../../../services/api_client.dart';
import '../../../services/report_service.dart';
import '../../../theme/app_theme.dart';

class ReportBottomSheet extends StatefulWidget {
  final String targetUserId;

  const ReportBottomSheet({super.key, required this.targetUserId});

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  ReportReason? _selectedReason;
  bool _isLoading = false;
  String? _error;

  static const _reasons = [
    {'value': ReportReason.spam, 'label': 'Spam'},
    {'value': ReportReason.harassment, 'label': 'Quấy rối'},
    {'value': ReportReason.fakeProfile, 'label': 'Hồ sơ giả'},
    {'value': ReportReason.inappropriate, 'label': 'Nội dung không phù hợp'},
    {'value': ReportReason.other, 'label': 'Khác'},
  ];

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ReportService(ApiClient()).createReport(
        targetUserId: widget.targetUserId,
        reason: _selectedReason!,
      );

      if (mounted) {
        Navigator.of(context).pop(result.reportId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = BondyErrorMapper.message(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Báo cáo người dùng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn lý do báo cáo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._reasons.map((reason) => _buildReasonTile(reason)),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedReason != null && !_isLoading
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: BondyColors.primary,
                disabledBackgroundColor: BondyColors.primary.withValues(
                  alpha: 0.3,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Xác nhận',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonTile(Map<String, dynamic> reason) {
    final isSelected = _selectedReason == reason['value'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            setState(() => _selectedReason = reason['value'] as ReportReason),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? BondyColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? BondyColors.primary : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                reason['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: BondyColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
