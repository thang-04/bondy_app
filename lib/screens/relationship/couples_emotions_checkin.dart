import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class CouplesEmotionsCheckin extends StatefulWidget {
  const CouplesEmotionsCheckin({super.key});

  @override
  State<CouplesEmotionsCheckin> createState() => _CouplesEmotionsCheckinState();
}

class _CouplesEmotionsCheckinState extends State<CouplesEmotionsCheckin> {
  String? _selectedEmoji;

  final List<Map<String, String>> _emotions = [
    {'emoji': '😊', 'label': 'Hạnh phúc'},
    {'emoji': '😌', 'label': 'Bình yên'},
    {'emoji': '🥰', 'label': 'Yêu thương'},
    {'emoji': '🤩', 'label': 'Hào hứng'},
    {'emoji': '😕', 'label': 'Bối rối'},
    {'emoji': '😢', 'label': 'Buồn bã'},
    {'emoji': '😤', 'label': 'Căng thẳng'},
    {'emoji': '😰', 'label': 'Lo lắng'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BondyColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Check-in cảm xúc',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiện tại bạn đang cảm thấy như thế nào?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: BondyColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cùng chia sẻ với đối phương để thấu hiểu nhau hơn nhé.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: BondyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _emotions.length,
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final isSelected = _selectedEmoji == emotion['emoji'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmoji = emotion['emoji']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFE5E5) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF5252) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emotion['emoji']!,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                emotion['label']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFFFF5252) : BondyColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Để lại lời nhắn (tùy chọn)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hôm nay tớ thấy...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _selectedEmoji == null
                  ? null
                  : () {
                      // Show confirmation
                      Navigator.pushNamed(context, '/relationship/confirmed');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BondyColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Chia sẻ với Hoan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
