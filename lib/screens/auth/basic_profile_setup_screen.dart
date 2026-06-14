import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_router.dart';
import '../../services/profile_service.dart';
import '../../core/bondy_error_mapper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class BasicProfileSetupScreen extends StatefulWidget {
  const BasicProfileSetupScreen({super.key});

  @override
  State<BasicProfileSetupScreen> createState() =>
      _BasicProfileSetupScreenState();
}

class _BasicProfileSetupScreenState extends State<BasicProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  final _profileService = ProfileService();
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isSubmitting = false;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  /*
  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      _selectedGender != null &&
      _bioController.text.trim().isNotEmpty &&
      _selectedInterests.isNotEmpty;
  */

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.isNotEmpty &&
      _selectedDate != null &&
      _selectedGender != null;

  Future<void> _submitProfile() async {
    final selectedDate = _selectedDate;
    final selectedGender = _selectedGender;
    if (!_isValid ||
        selectedDate == null ||
        selectedGender == null ||
        _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _profileService.updateProfile(
        fullName: _nameController.text.trim(),
        gender: selectedGender,
        birthDate: selectedDate,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      if (!mounted) return;
      await OnboardingRouter.navigateToNextStep(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BondyErrorMapper.message(error)),
          backgroundColor: BondyColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo hồ sơ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Tên hiển thị ────────────────────────────────────────────
              Text(
                'Tên hiển thị',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('profile_name_field'),
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Nhập tên của bạn'),
              ),
              const SizedBox(height: 24),

              // ── Ngày sinh ───────────────────────────────────────────────
              Text(
                'Ngày sinh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                key: const Key('profile_birthdate_field'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: BondyColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BondyColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Chọn ngày sinh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? BondyColors.textPrimary
                              : BondyColors.textHint,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: BondyColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Gender
              Text(
                'Giới tính',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender;
                  final genderKey = switch (gender) {
                    'Nam' => 'profile_gender_nam',
                    'Nữ' => 'profile_gender_nu',
                    'Khác' => 'profile_gender_khac',
                    _ => 'profile_gender_unknown',
                  };
                  return Expanded(
                    child: GestureDetector(
                      key: Key(genderKey),
                      onTap: () => setState(() => _selectedGender = gender),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: gender != _genders.last ? 12 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? BondyColors.primaryLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? BondyColors.primary
                                : BondyColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            gender,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? BondyColors.primary
                                  : BondyColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Tiểu sử ───────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Tiểu sử (Bio)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: GoogleFonts.plusJakartaSans(
                      color: BondyColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Giới thiệu đôi chút về bản thân bạn...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Removed Job and Education Sections
              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Removed Interests Section
              const SizedBox(height: 48),
              BondyButton(
                key: const Key('profile_continue_button'),
                text: _isSubmitting ? 'Đang lưu...' : 'Tiếp tục',
                onPressed: _isValid ? _submitProfile : () {},
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
