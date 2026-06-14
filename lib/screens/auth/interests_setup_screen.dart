import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_router.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class InterestsSetupScreen extends StatefulWidget {
  /// [fromProfile] = true khi mở từ màn hình Profile (không phải onboarding).
  /// Khi đó sẽ dùng Navigator.pop() thay vì OnboardingRouter.
  final bool fromProfile;

  const InterestsSetupScreen({super.key, this.fromProfile = false});

  @override
  State<InterestsSetupScreen> createState() => _InterestsSetupScreenState();
}

class _InterestsSetupScreenState extends State<InterestsSetupScreen> {
  final _profileService = ProfileService();
  List<Map<String, dynamic>> _availableInterests = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Load song song: danh sách tất cả interests + interests user đã chọn
      final results = await Future.wait([
        _profileService.getInterests(),
        _profileService.getUserInterests(),
      ]);
      if (mounted) {
        setState(() {
          _availableInterests = results[0] as List<Map<String, dynamic>>;
          final selected = results[1] as List<String>;
          _selectedIds
            ..clear()
            ..addAll(selected);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách sở thích';
          _isLoading = false;
        });
      }
    }
  }

  bool get _isValid => _selectedIds.length >= 3;

  Future<void> _saveInterests() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _profileService.saveInterests(_selectedIds.toList());
      if (!mounted) return;

      if (widget.fromProfile) {
        // Mở từ Profile → quay lại và báo đã thay đổi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật sở thích ✓',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Đang trong onboarding → đến bước tiếp theo
        await OnboardingRouter.navigateToNextStep(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu sở thích: $e'),
            backgroundColor: BondyColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sở thích',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: widget.fromProfile && !_isLoading
            ? [
                TextButton(
                  onPressed: _isValid ? _saveInterests : null,
                  child: Text(
                    _isSubmitting ? 'Đang lưu...' : 'Lưu',
                    style: GoogleFonts.plusJakartaSans(
                      color: _isValid
                          ? BondyColors.primary
                          : BondyColors.textHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: BondyColors.primary),
              )
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(color: BondyColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              child: Text(
                'Thử lại',
                style: GoogleFonts.plusJakartaSans(color: BondyColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Sở thích của bạn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn ít nhất 3 sở thích để chúng tôi gợi ý những người phù hợp.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Counter badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isValid
                        ? BondyColors.primaryLight
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedIds.length} đã chọn${_isValid ? ' ✓' : ' (tối thiểu 3)'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isValid
                          ? BondyColors.primary
                          : BondyColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableInterests.map((interest) {
                    final id = interest['id']?.toString() ?? '';
                    final name = interest['name']?.toString() ?? '';
                    final isSelected = _selectedIds.contains(id);
                    return _InterestChip(
                      label: name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(id);
                          } else {
                            _selectedIds.add(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        // Chỉ hiện nút ở dưới khi đang onboarding (fromProfile = false)
        if (!widget.fromProfile)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: BondyButton(
              text: _isSubmitting
                  ? 'Đang lưu...'
                  : _isValid
                  ? 'Tiếp tục'
                  : 'Chọn ít nhất 3 sở thích',
              onPressed: _isValid && !_isSubmitting ? _saveInterests : () {},
            ),
          ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? BondyColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? BondyColors.primary : BondyColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BondyColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? BondyColors.primary : BondyColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
