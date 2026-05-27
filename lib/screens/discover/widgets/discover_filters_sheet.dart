import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/discover/discover_profile_model.dart';
import '../../../services/discover_service.dart';
import '../../../theme/app_theme.dart';

class DiscoverFiltersSheet extends StatefulWidget {
  final DiscoverService service;
  final DiscoverFilters? initial;

  const DiscoverFiltersSheet({
    super.key,
    required this.service,
    this.initial,
  });

  @override
  State<DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

const _allVibes = [
  ('chill', 'Nhẹ nhàng'),
  ('serious', 'Nghiêm túc'),
  ('adventurous', 'Năng động'),
  ('creative', 'Sáng tạo'),
  ('intellectual', 'Trí tuệ'),
  ('playful', 'Vui vẻ'),
];

class _DiscoverFiltersSheetState extends State<DiscoverFiltersSheet> {
  late int _minAge;
  late int _maxAge;
  late double _maxDistance;
  late Set<String> _selectedVibes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _minAge = widget.initial?.minAge ?? 18;
    _maxAge = widget.initial?.maxAge ?? 45;
    _maxDistance = (widget.initial?.maxDistance ?? 50).toDouble();
    _selectedVibes = Set.from(widget.initial?.vibes ?? []);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final filters = DiscoverFilters(
        minAge: _minAge,
        maxAge: _maxAge,
        maxDistance: _maxDistance.round(),
        vibes: _selectedVibes.isEmpty ? null : _selectedVibes.toList(),
      );
      await widget.service.saveFilters(filters);
      if (!mounted) return;
      Navigator.pop(context, filters);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được bộ lọc: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bộ lọc khám phá',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Text('Độ tuổi: $_minAge – $_maxAge', style: _labelStyle()),
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
            'Khoảng cách tối đa: ${_maxDistance.round()} km',
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
          Text('Vibe / Phong cách', style: _labelStyle()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allVibes.map((vibe) {
              final selected = _selectedVibes.contains(vibe.$1);
              return FilterChip(
                label: Text(vibe.$2),
                selected: selected,
                selectedColor: BondyColors.primary.withValues(alpha: 0.15),
                checkmarkColor: BondyColors.primary,
                labelStyle: TextStyle(
                  color: selected ? BondyColors.primary : BondyColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedVibes.add(vibe.$1);
                    } else {
                      _selectedVibes.remove(vibe.$1);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: BondyColors.textSecondary,
      );
}
