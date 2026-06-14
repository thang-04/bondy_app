import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bondy_button.dart';

class DeepMatchSetupScreen extends StatefulWidget {
  const DeepMatchSetupScreen({super.key});

  @override
  State<DeepMatchSetupScreen> createState() => _DeepMatchSetupScreenState();
}

class _DeepMatchSetupScreenState extends State<DeepMatchSetupScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  UserProfileModel? _profile;

  int _currentStep = 0; // 0: Zodiac, 1: Free Time, 2: Desired Partner

  // Step 1: Zodiac Sign & Preferences
  String? _selectedZodiac;
  final List<String> _selectedZodiacPrefs = [];

  // Step 2: Free Time Slots
  final List<String> _selectedFreeTimes = [];

  // Step 3: Desired Partner Type
  String? _selectedPartnerType;

  // Static translations & assets
  final Map<String, String> _zodiacNames = const {
    'aries': 'Bạch Dương',
    'taurus': 'Kim Ngưu',
    'gemini': 'Song Tử',
    'cancer': 'Cự Giải',
    'leo': 'Sư Tử',
    'virgo': 'Xử Nữ',
    'libra': 'Thiên Bình',
    'scorpio': 'Bọ Cạp',
    'sagittarius': 'Nhân Mã',
    'capricorn': 'Ma Kết',
    'aquarius': 'Bảo Bình',
    'pisces': 'Song Ngư',
  };

  final Map<String, String> _zodiacSymbols = const {
    'aries': '♈',
    'taurus': '♉',
    'gemini': '♊',
    'cancer': '♋',
    'leo': '♌',
    'virgo': '♍',
    'libra': '♎',
    'scorpio': '♏',
    'sagittarius': '♐',
    'capricorn': '♑',
    'aquarius': '♒',
    'pisces': '♓',
  };

  final Map<String, Map<String, dynamic>> _freeTimeData = const {
    'morning': {
      'label': 'Buổi sáng',
      'icon': Icons.wb_sunny_outlined,
      'desc': '6:00 - 12:00',
    },
    'afternoon': {
      'label': 'Buổi chiều',
      'icon': Icons.wb_twilight,
      'desc': '12:00 - 18:00',
    },
    'evening': {
      'label': 'Buổi tối',
      'icon': Icons.nightlight_round_outlined,
      'desc': '18:00 - 24:00',
    },
    'weekend': {
      'label': 'Cuối tuần',
      'icon': Icons.calendar_month_outlined,
      'desc': 'Thứ 7 & Chủ Nhật',
    },
    'flexible': {
      'label': 'Linh hoạt',
      'icon': Icons.all_inclusive,
      'desc': 'Có thể sắp xếp bất kỳ lúc nào',
    },
  };

  final Map<String, Map<String, dynamic>> _partnerTypeData = const {
    'confidant': {
      'label': 'Bạn tâm sự',
      'icon': Icons.chat_bubble_outline_rounded,
      'desc': 'Một người lắng nghe và chia sẻ mọi buồn vui',
    },
    'lover': {
      'label': 'Người yêu',
      'icon': Icons.favorite_border_rounded,
      'desc': 'Kết nối lãng mạn, tìm hiểu tiến tới tình yêu',
    },
    'life_partner': {
      'label': 'Bạn đời',
      'icon': Icons.volunteer_activism_outlined,
      'desc': 'Tìm kiếm một mối quan hệ cam kết lâu dài',
    },
    'undecided': {
      'label': 'Chưa xác định',
      'icon': Icons.help_outline_rounded,
      'desc': 'Mở lòng với mọi kiểu kết nối tự nhiên nhất',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;

        // Pre-fill existing deep match data if available
        if (profile.zodiacSign != null) {
          _selectedZodiac = profile.zodiacSign;
        }
        if (profile.zodiacPreferences.isNotEmpty) {
          _selectedZodiacPrefs.addAll(profile.zodiacPreferences);
        }
        if (profile.freeTimeSlots.isNotEmpty) {
          _selectedFreeTimes.addAll(profile.freeTimeSlots);
        }
        if (profile.desiredPartnerType != null) {
          _selectedPartnerType = profile.desiredPartnerType;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thông tin hồ sơ: $e')));
      }
    }
  }

  int? get _lifePathNumber {
    final dob = _profile?.birthDate;
    if (dob == null) return null;

    int sumDigits(int num) {
      int sum = num;
      while (sum > 9) {
        if (sum == 11 || sum == 22 || sum == 33) {
          return sum;
        }
        sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
      }
      return sum;
    }

    final daySum = sumDigits(dob.day);
    final monthSum = sumDigits(dob.month);
    final yearSum = sumDigits(dob.year);

    int total = daySum + monthSum + yearSum;
    while (total > 9) {
      if (total == 11 || total == 22 || total == 33) {
        return total;
      }
      total = total.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return total;
  }

  String _getLifePathDesc(int? number) {
    switch (number) {
      case 1:
        return 'Người tiên phong, độc lập và quyết đoán.';
      case 2:
        return 'Người hòa giải, nhạy cảm và hợp tác.';
      case 3:
        return 'Người truyền cảm hứng, sáng tạo và giao tiếp tốt.';
      case 4:
        return 'Người thực tế, chăm chỉ và đáng tin cậy.';
      case 5:
        return 'Người tự do, phiêu lưu và thích thích nghi.';
      case 6:
        return 'Người nuôi dưỡng, trách nhiệm và yêu thương gia đình.';
      case 7:
        return 'Người tìm kiếm tri thức, phân tích và sâu sắc.';
      case 8:
        return 'Người điều hành, thành công và định hướng mục tiêu.';
      case 9:
        return 'Người nhân đạo, cống hiến và vị tha.';
      case 11:
        return 'Người có trực giác nhạy bén, tâm linh sâu sắc.';
      case 22:
        return 'Người kiến tạo bậc thầy, hiện thực hóa ước mơ lớn.';
      case 33:
        return 'Người thầy vĩ đại, dẫn dắt bằng tình yêu thương.';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _profileService.saveDeepMatch(
        zodiacSign: _selectedZodiac,
        zodiacPreferences: _selectedZodiacPrefs,
        freeTimeSlots: _selectedFreeTimes,
        desiredPartnerType: _selectedPartnerType,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Extract targetRoute from navigation arguments if any
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final isEditMode = args?['isEditMode'] == true;

      if (isEditMode) {
        Navigator.of(context).pop(true);
        return;
      }

      final targetRoute = args?['targetRoute']?.toString() ?? '/home';
      final targetArgs = args?['targetArguments'] as Map<String, dynamic>?;

      Navigator.of(context).pushNamedAndRemoveUntil(
        targetRoute,
        (_) => false,
        arguments: targetArgs,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu thông tin DeepMatch: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      // If Onboarding Setup, go to previous screen
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int? lifePath = _lifePathNumber;

    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: BondyColors.textPrimary,
            size: 18,
          ),
          onPressed: _prevStep,
        ),
        title: Text(
          'Thiết lập DeepMatch',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? BondyColors.primary : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) _buildZodiacStep(lifePath),
                      if (_currentStep == 1) _buildFreeTimeStep(),
                      if (_currentStep == 2) _buildPartnerTypeStep(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              BondyButton(
                text: _currentStep == 2 ? 'Hoàn thành' : 'Tiếp tục',
                isLoading: _isSubmitting,
                onPressed: _isNextButtonEnabled() ? _nextStep : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNextButtonEnabled() {
    if (_currentStep == 0) {
      return _selectedZodiac != null && _selectedZodiacPrefs.isNotEmpty;
    }
    if (_currentStep == 1) {
      return _selectedFreeTimes.isNotEmpty;
    }
    if (_currentStep == 2) {
      return _selectedPartnerType != null;
    }
    return false;
  }

  Widget _buildZodiacStep(int? lifePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lifePath != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$lifePath',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số chủ đạo Tần số học của bạn',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBE123C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getLifePathDesc(lifePath),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9F1239),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        Text(
          'Cung hoàng đạo của bạn là gì?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildZodiacGrid(
          selected: _selectedZodiac,
          onSelected: (code) => setState(() => _selectedZodiac = code),
        ),
        const SizedBox(height: 28),

        Text(
          'Bạn muốn ghép đôi với cung hoàng đạo nào?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Có thể chọn nhiều cung hoàng đạo bạn cảm thấy hợp nhất.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildZodiacGrid(
          multiSelect: true,
          selectedList: _selectedZodiacPrefs,
          onSelected: (code) {
            setState(() {
              if (_selectedZodiacPrefs.contains(code)) {
                _selectedZodiacPrefs.remove(code);
              } else {
                _selectedZodiacPrefs.add(code);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildZodiacGrid({
    bool multiSelect = false,
    String? selected,
    List<String>? selectedList,
    required Function(String) onSelected,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _zodiacNames.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final code = _zodiacNames.keys.elementAt(index);
        final name = _zodiacNames[code]!;
        final symbol = _zodiacSymbols[code]!;

        final isSelected = multiSelect
            ? (selectedList?.contains(code) ?? false)
            : (selected == code);

        return GestureDetector(
          onTap: () => onSelected(code),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? BondyColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? BondyColors.primary
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 24,
                    color: isSelected ? Colors.white : BondyColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : BondyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreeTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khung thời gian rảnh rỗi của bạn?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Giúp tìm kiếm những người có lịch sinh hoạt tương đồng.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _freeTimeData.length,
          itemBuilder: (context, index) {
            final key = _freeTimeData.keys.elementAt(index);
            final data = _freeTimeData[key]!;
            final isSelected = _selectedFreeTimes.contains(key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedFreeTimes.contains(key)) {
                      _selectedFreeTimes.remove(key);
                    } else {
                      _selectedFreeTimes.add(key);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? BondyColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? BondyColors.primary
                          : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        data['icon'] as IconData,
                        color: isSelected ? Colors.white : BondyColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['label'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : BondyColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['desc'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : BondyColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.black12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPartnerTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn đang tìm kiếm điều gì?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mục tiêu kết nối rõ ràng giúp hai tâm hồn dễ chạm vào nhau hơn.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: BondyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _partnerTypeData.length,
          itemBuilder: (context, index) {
            final key = _partnerTypeData.keys.elementAt(index);
            final data = _partnerTypeData[key]!;
            final isSelected = _selectedPartnerType == key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPartnerType = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? BondyColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? BondyColors.primary
                          : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        data['icon'] as IconData,
                        color: isSelected ? Colors.white : BondyColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['label'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : BondyColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['desc'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : BondyColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.black12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
