import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

import '../healing/healing_stitch_style.dart';

class RelationshipConnectedScreen extends StatefulWidget {
  const RelationshipConnectedScreen({super.key});

  @override
  State<RelationshipConnectedScreen> createState() =>
      _RelationshipConnectedScreenState();
}

class _RelationshipConnectedScreenState
    extends State<RelationshipConnectedScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  String? _partnerName;
  String? _partnerPhoto;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiController.play();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _partnerName = args['name'] as String?;
      _partnerPhoto = args['photo'] as String?;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient Cam Hồng ảo diệu
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF5F0),
                  Color(0xFFFFF0EB),
                  Color(0xFFFFF9F5),
                ],
              ),
            ),
          ),

          // Hiệu ứng Confetti nổ từ trên xuống
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFB7B2),
                Color(0xFFFFDAC1),
                Color(0xFFE2F0CB),
                Color(0xFFB5EAD7),
                Color(0xFFFF9A9E),
                Color(0xFFFECFEF),
              ],
              gravity: 0.15,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
            ),
          ),

          // Nội dung chính
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // Tâm điểm Avatar đôi
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Nền tròn trắng làm nổi bật
                        Container(
                          width: size.width * 0.65,
                          height: size.width * 0.65,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                        ),
                        // Hai avatar lồng chéo nghiêng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar của tôi (Trái)
                            Transform.rotate(
                              angle: -0.1, // ~ -6 độ
                              child: Container(
                                width: size.width * 0.28,
                                height: size.width * 0.28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  color: Colors.grey.shade200,
                                ),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCsgnYy8VW20CiYCVCqg8zVPiFE7qcVqSprT2bF4XVJHKShNuiZH4QvrSimg7ny5ofI1wWBMphBWGyCJiUUlCrwbfAHTcSo8XxION3MupzLDXLWzecVzCoTZGh3diOCqobJDjMkUh9Al1LTTSC4Ykd1BYxeDdHKqf-tzCT6SBTKAph-g5f0YldSABwVsW37Rmpz-oeeu8wgBttoAfisoCHmhmxONpBBjdzprzcIs2s3LZD_eJ7rgUtTBw6EqgyC9nHAdhSSKTmjAdd6',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: -20),
                            // Avatar đối phương (Phải)
                            Transform.rotate(
                              angle: 0.1, // ~ 6 độ
                              child: Stack(
                                children: [
                                  Container(
                                    width: size.width * 0.28,
                                    height: size.width * 0.28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      color: Colors.grey.shade200,
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          _partnerPhoto != null &&
                                              _partnerPhoto!.startsWith('http')
                                          ? NetworkImage(_partnerPhoto!)
                                          : const NetworkImage(
                                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDLFtkpJawOulzk07g6ONeRHHCNIyJrGyaF73PQyJrva98w8x4CgZE-4Aa_AA82hxzO6qpGwV7PsXoeQr4K_gJFP9dBMogVYmjiEULvLdcJQpdWXh-02TVqgontL8ili4xvUIFWYv3XK8qpqJGA76NzO2P2SsaRg09JtfRhFcPS3feVxEGf6F-Xd_vTs18RC4bDkD9a1-LV-TLRR7IGYuoLHu58h3JV3Qf7CtQwkPmVLOJa1UGXTizsnldFaC7dVqxAzb8eCWvTa9lx',
                                                )
                                                as ImageProvider,
                                    ),
                                  ),
                                  // Icon Trái tim kết nối lồi ra
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFF8C42),
                                              Color(0xFFFF4B7D),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tiêu đề ăn mừng
                  Text(
                    '🎉',
                    style: GoogleFonts.plusJakartaSans(fontSize: 40),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _partnerName != null
                        ? 'Bạn và $_partnerName\nđã chính thức chung đôi'
                        : 'Hai bạn đã chính thức chung đôi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: HealingStitchColors.textMain,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bắt đầu hành trình của hai bạn ngay bây giờ.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: HealingStitchColors.textSoft,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Panel Kỷ niệm Glassmorphism
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFFFF4B7D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Ngày kỷ niệm',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: HealingStitchColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Hôm nay',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF4B7D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button CTA đi tới Góc mối quan hệ
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8C42), Color(0xFFFF4B7D)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF4B7D,
                          ).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đi tới Góc Mối quan hệ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
