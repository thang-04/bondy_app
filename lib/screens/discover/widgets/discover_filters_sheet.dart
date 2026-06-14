import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/discover/discover_profile_model.dart';
import '../../../services/discover_service.dart';
import '../../../theme/app_theme.dart';

class DiscoverFiltersSheet extends StatefulWidget {
  final DiscoverService service;
  final DiscoverFilters? initial;

  const DiscoverFiltersSheet({super.key, required this.service, this.initial});

  @override
  State<DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

const _targetGenders = [
  ('FEMALE', 'Nu'),
  ('MALE', 'Nam'),
  ('OTHER', 'Khac'),
  ('NON_BINARY', 'Non-binary'),
];

const _goalOptions = [
  ('DATING', 'Hen ho'),
  ('LONG_TERM', 'Lau dai'),
  ('MARRIAGE', 'Hon nhan'),
  ('FRIENDSHIP', 'Ban be'),
  ('NOT_SURE', 'Chua ro'),
];

const _allVibes = [
  ('chill', 'Nhe nhang'),
  ('serious', 'Nghiem tuc'),
  ('adventurous', 'Nang dong'),
  ('creative', 'Sang tao'),
  ('intellectual', 'Tri tue'),
  ('playful', 'Vui ve'),
];

class _DiscoverFiltersSheetState extends State<DiscoverFiltersSheet> {
  late int _minAge;
  late int _maxAge;
  late double _maxDistance;
  late Set<String> _selectedGenders;
  late Set<String> _selectedGoals;
  late Set<String> _selectedVibes;
  late double _minCompatibility;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _minAge = widget.initial?.minAge ?? 18;
    _maxAge = widget.initial?.maxAge ?? 45;
    _maxDistance = (widget.initial?.maxDistance ?? 50).toDouble();
    _selectedGenders = Set.from(widget.initial?.genders ?? []);
    _selectedGoals = Set.from(widget.initial?.goals ?? []);
    _selectedVibes = Set.from(widget.initial?.vibes ?? []);
    _minCompatibility = (widget.initial?.minCompatibility ?? 0).toDouble();
  }

  Future<void> _save() async {
    if (_selectedGenders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hay chon gioi tinh ban muon match.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final filters = DiscoverFilters(
        minAge: _minAge,
        maxAge: _maxAge,
        maxDistance: _maxDistance.round(),
        genders: _selectedGenders.toList(),
        goals: _selectedGoals.isEmpty ? null : _selectedGoals.toList(),
        vibes: _selectedVibes.isEmpty ? null : _selectedVibes.toList(),
        minCompatibility: _minCompatibility <= 0
            ? null
            : _minCompatibility.round(),
      );
      await widget.service.saveFilters(filters);
      if (!mounted) return;
      Navigator.pop(context, filters);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Khong luu duoc bo loc: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(Set<String> values, String code, bool selected) {
    setState(() {
      if (selected) {
        values.add(code);
      } else {
        values.remove(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bo loc kham pha',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildChipSection(
              title: 'Muon thay ai',
              values: _targetGenders,
              selected: _selectedGenders,
              keyPrefix: 'discover_filter_gender',
            ),
            const SizedBox(height: 20),
            Text('Do tuoi: $_minAge - $_maxAge', style: _labelStyle()),
            RangeSlider(
              values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
              min: 18,
              max: 60,
              divisions: 42,
              activeColor: BondyColors.primary,
              onChanged: (v) => setState(() {
                _minAge = v.start.round();
                _maxAge = v.end.round();
              }),
            ),
            Text(
              'Khoang cach toi da: ${_maxDistance.round()} km',
              style: _labelStyle(),
            ),
            Slider(
              value: _maxDistance,
              min: 5,
              max: 200,
              divisions: 39,
              activeColor: BondyColors.primary,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
            _buildChipSection(
              title: 'Muc tieu hen ho',
              values: _goalOptions,
              selected: _selectedGoals,
              keyPrefix: 'discover_filter_goal',
            ),
            const SizedBox(height: 20),
            _buildChipSection(
              title: 'Vibe / Phong cach',
              values: _allVibes,
              selected: _selectedVibes,
              keyPrefix: 'discover_filter_vibe',
            ),
            const SizedBox(height: 20),
            Text(
              _minCompatibility <= 0
                  ? 'Tuong thich toi thieu: Bat ky'
                  : 'Tuong thich toi thieu: ${_minCompatibility.round()}%',
              style: _labelStyle(),
            ),
            Slider(
              value: _minCompatibility,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: BondyColors.primary,
              onChanged: (v) => setState(() => _minCompatibility = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('discover_filter_apply_button'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ap dung'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required String title,
    required List<(String, String)> values,
    required Set<String> selected,
    required String keyPrefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _labelStyle()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((option) {
            final isSelected = selected.contains(option.$1);
            return FilterChip(
              key: Key('${keyPrefix}_${option.$1}'),
              label: Text(option.$2),
              selected: isSelected,
              selectedColor: BondyColors.primary.withValues(alpha: 0.15),
              checkmarkColor: BondyColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? BondyColors.primary
                    : BondyColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (value) => _toggle(selected, option.$1, value),
            );
          }).toList(),
        ),
      ],
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    color: BondyColors.textSecondary,
    fontWeight: FontWeight.w600,
  );
}
