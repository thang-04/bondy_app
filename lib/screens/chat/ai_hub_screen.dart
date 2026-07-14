import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai_mode_catalog.dart';
import '../../models/ai_conversation.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

/// Theo dõi điều hướng để làm mới lịch sử khi quay lại AI hub. Được đăng ký
/// trong `navigatorObservers` của MaterialApp (main.dart).
final RouteObserver<PageRoute<dynamic>> aiHubRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _animController;
  final AiService _aiService = AiService(ApiClient());

  List<AiConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      aiHubRouteObserver.subscribe(this, route);
    }
  }

  /// Quay lại AI hub từ một màn chat/đọc bài phía trên → nạp lại lịch sử để
  /// cuộc trò chuyện vừa tạo xuất hiện ngay, không cần thoát hẳn app.
  @override
  void didPopNext() {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final response = await _aiService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = response.conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    aiHubRouteObserver.unsubscribe(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingBanner(),
            const SizedBox(height: 24),
            _buildSectionTitle('Chọn mode AI'),
            const SizedBox(height: 16),
            _buildModeGrid(context),
            const SizedBox(height: 28),
            _buildSectionTitle('Lịch sử trò chuyện'),
            const SizedBox(height: 12),
            _buildConversationHistory(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        color: BondyColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8C42)],
        ).createShader(bounds),
        child: Text(
          'AI Bondy',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(BondyRadius.lg),
        boxShadow: [
          BoxShadow(
            color: BondyColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text('🔮', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI mode & skill',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn đúng trợ lý cho câu hỏi của bạn',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BondyColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context) {
    final modes = AiModeCatalog.modes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.06,
        ),
        itemCount: modes.length,
        itemBuilder: (context, index) =>
            _buildModeCard(context, modes[index], index),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    AiModeDescriptor descriptor,
    int index,
  ) {
    final colors = _modeColors(descriptor.mode);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 60),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          descriptor.routeName,
          arguments: descriptor.routeArguments.isEmpty
              ? {'mode': descriptor.mode.apiValue}
              : descriptor.routeArguments,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.$1, colors.$2],
            ),
            borderRadius: BorderRadius.circular(BondyRadius.md),
            border: Border.all(color: colors.$3.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.white.withValues(alpha: 0.82),
                  child: Image.asset(
                    descriptor.avatarAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          descriptor.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descriptor.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BondyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descriptor.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: BondyColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistory() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BondyColors.primary),
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BondyRadius.md),
          border: Border.all(color: BondyColors.divider, width: 1),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.chat_bubble_outline, color: BondyColors.textSecondary, size: 32),
              const SizedBox(height: 12),
              Text(
                'Chưa có cuộc trò chuyện nào',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn một mode AI ở trên để bắt đầu',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: BondyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _conversations.map((conv) => _buildConversationItem(conv)).toList(),
    );
  }

  Widget _buildConversationItem(AiConversation conversation) {
    // Find mode descriptor to get icon and color
    final modeEnum = AiChatMode.values.firstWhere(
      (m) => m.apiValue == conversation.mode,
      orElse: () => AiChatMode.defaultMode,
    );
    final descriptor = AiModeCatalog.modes.firstWhere(
      (m) => m.mode == modeEnum,
      orElse: () => AiModeCatalog.modes.first,
    );
    final colors = _modeColors(modeEnum);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(BondyRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện?'),
            content: const Text('Hành động này không thể hoàn tác.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy', style: TextStyle(color: BondyColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _aiService.deleteConversation(conversation.id);
        setState(() {
          _conversations.removeWhere((c) => c.id == conversation.id);
        });
      },
      child: GestureDetector(
        onTap: () {
          // Navigate to specific chat screen with conversationId
          Navigator.pushNamed(
            context,
            descriptor.routeName,
            arguments: {
              ...descriptor.routeArguments,
              if (descriptor.routeArguments.isEmpty) 'mode': descriptor.mode.apiValue,
              'conversationId': conversation.id,
            },
          ).then((_) => _loadConversations()); // Reload history when back
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BondyRadius.md),
            border: Border.all(color: BondyColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.$1,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(descriptor.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          descriptor.title,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.$3,
                          ),
                        ),
                        Text(
                          ' · ${conversation.relativeTime}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: BondyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BondyColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _modeColors(AiChatMode mode) {
    switch (mode) {
      case AiChatMode.healing:
        return (
          const Color(0xFFEEFFF5),
          const Color(0xFFD6FFE8),
          const Color(0xFF10B981),
        );
      case AiChatMode.coach:
        return (
          const Color(0xFFFFEEF2),
          const Color(0xFFFFD6E0),
          const Color(0xFFFF6B9D),
        );
      case AiChatMode.plan:
        return (
          const Color(0xFFEAF7FF),
          const Color(0xFFD7ECFF),
          const Color(0xFF0284C7),
        );
      case AiChatMode.aiTuVi:
        return (
          const Color(0xFFFFF5EE),
          const Color(0xFFFFE8D6),
          const Color(0xFFFF8C42),
        );
      case AiChatMode.tarot:
        return (
          const Color(0xFFEEEEFF),
          const Color(0xFFD6D6FF),
          const Color(0xFF8B5CF6),
        );
      case AiChatMode.defaultMode:
        return (
          const Color(0xFFFFF8E7),
          const Color(0xFFFFEDD5),
          const Color(0xFFF59E0B),
        );
    }
  }
}
