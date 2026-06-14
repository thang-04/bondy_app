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
    ('FEMALE', 'Nu'),
    ('MALE', 'Nam'),
    ('OTHER', 'Khac'),
    ('NON_BINARY', 'Non-binary'),
  ];

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
        const SnackBar(content: Text('Hay chon gioi tinh ban muon match.')),
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
        SnackBar(content: Text('Khong luu duoc lua chon: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleGender(String code, bool selected) {
    setState(() {
      if (selected) {
        _selectedGenders.add(code);
      } else {
        _selectedGenders.remove(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(title: const Text('Tuy chon match')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ban muon match voi ai?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lua chon nay quyet dinh nhung ho so xuat hien trong Swipe.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: BondyColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genderOptions.map((option) {
                        final selected = _selectedGenders.contains(option.$1);
                        return FilterChip(
                          key: Key('match_pref_gender_${option.$1}'),
                          label: Text(option.$2),
                          selected: selected,
                          selectedColor: BondyColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: BondyColors.primary,
                          onSelected: (value) =>
                              _toggleGender(option.$1, value),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    BondyButton(
                      key: const Key('match_pref_continue_button'),
                      text: _isSubmitting ? 'Dang luu...' : 'Tiep tuc',
                      isLoading: _isSubmitting,
                      onPressed: _selectedGenders.isEmpty
                          ? null
                          : () => _submit(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
