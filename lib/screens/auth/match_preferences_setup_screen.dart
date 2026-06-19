import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/discover/discover_profile_model.dart';
import '../../services/discover_service.dart';
import '../../services/onboarding_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class MatchPreferencesSetupScreen extends StatefulWidget {
  const MatchPreferencesSetupScreen({super.key});

  @override
  State<MatchPreferencesSetupScreen> createState() =>
      _MatchPreferencesSetupScreenState();
}

class _MatchPreferencesSetupScreenState
    extends State<MatchPreferencesSetupScreen> {
  final DiscoverService _discoverService = DiscoverService();
  final Set<String> _selectedGenders = {};
  DiscoverFilters? _existingFilters;
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const _genderOptions = [
    ('MALE', 'Nam', '👨'),
    ('FEMALE', 'Nữ', '👩'),
    ('TRANS_MALE', 'Chuyển giới Nam', '🏳️‍⚧️'),
    ('TRANS_FEMALE', 'Chuyển giới Nữ', '🏳️‍⚧️'),
    ('NON_BINARY', 'Non-binary', '⚧️'),
    ('GENDERQUEER', 'Genderqueer', '🌈'),
    ('AGENDER', 'Vô tính', '⚪'),
    ('OTHER', 'Khác', '🔮'),
  ];

  bool get _isAllSelected => _selectedGenders.length == _genderOptions.length;

  @override
  void initState() {
    super.initState();
    _loadExistingFilters();
  }

  Future<void> _loadExistingFilters() async {
    try {
      final filters = await _discoverService.getFilters();
      if (!mounted) return;
      setState(() {
        _existingFilters = filters;
        _selectedGenders.addAll(filters.genders ?? const []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedGenders.isEmpty || _isSubmitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn giới tính bạn muốn match.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final existing = _existingFilters;
      await _discoverService.saveFilters(
        DiscoverFilters(
          minAge: existing?.minAge ?? 18,
          maxAge: existing?.maxAge ?? 100,
          maxDistance: existing?.maxDistance ?? 50,
          genders: _selectedGenders.toList(),
          orientations: existing?.orientations,
          goals: existing?.goals,
          interests: existing?.interests,
          minCompatibility: existing?.minCompatibility,
          vibes: existing?.vibes,
        ),
      );
      if (!mounted) return;
      await OnboardingRouter.navigateToNextStep(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được lựa chọn: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedGenders.clear();
      } else {
        _selectedGenders.addAll(_genderOptions.map((o) => o.$1));
      }
    });
  }

  void _toggleGender(String code) {
    setState(() {
      if (_selectedGenders.contains(code)) {
        _selectedGenders.remove(code);
      } else {
        _selectedGenders.add(code);
      }
    });
  }

  Widget _buildGenderCard({
    required String code,
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? BondyColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BondyColors.primary : BondyColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BondyColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? BondyColors.primary : BondyColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: BondyColors.primary,
                size: 18,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: BondyColors.textHint.withValues(alpha: 0.3),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Tùy chọn match')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bạn muốn match với ai?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: BondyColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lựa chọn này quyết định những hồ sơ xuất hiện trong Swipe.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: BondyColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.1,
                            ),
                            itemCount: _genderOptions.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildGenderCard(
                                  code: 'ALL',
                                  label: 'Tất cả mọi người',
                                  emoji: '👥',
                                  isSelected: _isAllSelected,
                                  onTap: _toggleAll,
                                );
                              }
                              final option = _genderOptions[index - 1];
                              final isSelected =
                                  _selectedGenders.contains(option.$1);
                              return _buildGenderCard(
                                code: option.$1,
                                label: option.$2,
                                emoji: option.$3,
                                isSelected: isSelected,
                                onTap: () => _toggleGender(option.$1),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: BondyButton(
                      key: const Key('match_pref_continue_button'),
                      text: _isSubmitting ? 'Đang lưu...' : 'Tiếp tục',
                      isLoading: _isSubmitting,
                      onPressed: _selectedGenders.isEmpty
                          ? null
                          : () => _submit(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
