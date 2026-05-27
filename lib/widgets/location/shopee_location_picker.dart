import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class ShopeeLocationPicker extends StatefulWidget {
  final void Function(String address, double? latitude, double? longitude) onSelected;

  const ShopeeLocationPicker({
    super.key,
    required this.onSelected,
  });

  @override
  State<ShopeeLocationPicker> createState() => _ShopeeLocationPickerState();
}

class _ShopeeLocationPickerState extends State<ShopeeLocationPicker> {
  final _searchController = TextEditingController();

  final List<String> _suggestedLocations = const [
    'Quận 1, Thành phố Hồ Chí Minh',
    'Quận 3, Thành phố Hồ Chí Minh',
    'Quận 7, Thành phố Hồ Chí Minh',
    'Thủ Đức, Thành phố Hồ Chí Minh',
    'Ba Đình, Hà Nội',
    'Hoàn Kiếm, Hà Nội',
    'Hải Châu, Đà Nẵng',
    'Ninh Kiều, Cần Thơ',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredLocations {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _suggestedLocations;

    return _suggestedLocations
        .where((location) => location.toLowerCase().contains(keyword))
        .toList();
  }

  void _selectLocation(String address) {
    widget.onSelected(address, null, null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locations = _filteredLocations;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn địa chỉ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tìm tỉnh/thành phố, quận/huyện...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: BondyColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: locations.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy địa chỉ phù hợp',
                          style: GoogleFonts.plusJakartaSans(
                            color: BondyColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        itemCount: locations.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final address = locations[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: BondyColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: BondyColors.primary,
                              ),
                            ),
                            title: Text(
                              address,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: BondyColors.textPrimary,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _selectLocation(address),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
