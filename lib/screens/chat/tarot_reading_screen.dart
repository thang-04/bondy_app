import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../widgets/common/ai_markdown_text.dart';

class TarotReadingScreen extends StatefulWidget {
  final AiService? aiService;

  const TarotReadingScreen({super.key, this.aiService});

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  late final AiService _aiService = widget.aiService ?? AiService(ApiClient());
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _sessionId = 'tarot-${DateTime.now().millisecondsSinceEpoch}';
  final List<_TarotMessage> _chatMessages = [];

  final List<_TarotCardData> _allCards = [
    _TarotCardData(
      'The Star',
      'Lá bài đại diện cho niềm hy vọng và sự chữa lành. Quá khứ đã giúp bạn tìm lại niềm tin vào tình yêu.',
      '⭐',
    ),
    _TarotCardData(
      'The Lovers',
      'Biểu tượng của sự hòa hợp, gắn kết sâu sắc và lựa chọn từ trái tim.',
      '💕',
    ),
    _TarotCardData(
      'The Moon',
      'Đại diện cho trực giác, nỗi sợ và các khía cạnh còn ẩn giấu.',
      '🌙',
    ),
    _TarotCardData(
      'The Empress',
      'Đại diện cho sự nuôi dưỡng, phát triển và tình yêu vô điều kiện.',
      '👑',
    ),
    _TarotCardData(
      'The Fool',
      'Khởi đầu mới, sự tự do và lòng dũng cảm bước vào hành trình mới.',
      '🃏',
    ),
    _TarotCardData(
      'The Sun',
      'Niềm vui, sự rõ ràng và nguồn năng lượng tích cực trong tình yêu.',
      '☀️',
    ),
  ];

  late List<_TarotCardData> _selectedCards;
  late List<bool> _flipped;
  int? _activeCardIndex;
  bool _isSending = false;
  bool _didReadArguments = false;
  List<String> _intakeSummary = const [];

  @override
  void initState() {
    super.initState();
    _drawCards();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! Map<String, dynamic>) return;

      final summary = _summaryFromArgs(args['intakeSummary']);
      if (summary.isNotEmpty && mounted) {
        setState(() => _intakeSummary = summary);
      }

      final initialMessage = args['initialMessage'];
      final displayMessage = args['displayMessage']?.toString().trim();
      if (initialMessage is String && initialMessage.trim().isNotEmpty) {
        _sendMessage(
          initialMessage.trim(),
          displayMessage: displayMessage?.isNotEmpty == true
              ? displayMessage
              : null,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _drawCards() {
    final cards = List<_TarotCardData>.from(_allCards)..shuffle(Random());
    setState(() {
      _selectedCards = cards.take(3).toList();
      _flipped = [false, false, false];
      _activeCardIndex = null;
      _chatMessages
        ..clear()
        ..add(
          _TarotMessage(
            'Hãy lật từng lá bài bên trên để nhận thông điệp Tarot tình yêu hôm nay.',
            false,
          ),
        );
    });
  }

  void _flipCard(int index) {
    if (_flipped[index]) {
      setState(() => _activeCardIndex = index);
      return;
    }

    final position = _positionLabel(index);
    final card = _selectedCards[index];
    setState(() {
      _flipped[index] = true;
      _activeCardIndex = index;
      _chatMessages.add(
        _TarotMessage(
          'Bạn đã lật lá $position: ${card.name}.\n\nÝ nghĩa: ${card.meaning}',
          false,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text, {String? displayMessage}) async {
    final message = text.trim();
    if (message.isEmpty || _isSending) return;

    final assistantMessage = _TarotMessage('', false, streaming: true);
    setState(() {
      _isSending = true;
      _chatMessages.add(
        _TarotMessage(displayMessage ?? message, true, requestText: message),
      );
      _chatMessages.add(assistantMessage);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await for (final event in _aiService.streamChat(
        AiStreamChatRequest(
          messages: _buildRequestMessages(),
          mode: AiChatMode.tarot,
          sessionId: _sessionId,
        ),
      )) {
        if (!mounted) return;
        if (event.type == AiStreamEventType.chunk && event.chunk != null) {
          final chunk = event.chunk!;
          setState(() {
            if (chunk.startsWith('__STRIPPED__')) {
              assistantMessage.text = chunk.substring('__STRIPPED__'.length);
            } else {
              assistantMessage.text += chunk;
            }
          });
          _scrollToBottom();
        } else if (event.type == AiStreamEventType.error) {
          setState(() {
            assistantMessage.text =
                event.error ?? 'Mình xin lỗi, có lỗi xảy ra. Bạn thử lại nhé.';
          });
        }
      }

      if (assistantMessage.text.trim().isEmpty && mounted) {
        setState(() {
          assistantMessage.text =
              'Bạn có thể lật thêm lá bài hoặc hỏi cụ thể hơn về trải bài này.';
        });
      }
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() => assistantMessage.text = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        assistantMessage.text =
            'Mình xin lỗi, hiện chưa kết nối được AI. Bạn thử lại sau nhé.';
      });
    } finally {
      if (mounted) {
        setState(() {
          assistantMessage.streaming = false;
          _isSending = false;
        });
      }
    }
  }

  List<AiChatMessage> _buildRequestMessages() {
    return _chatMessages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => AiChatMessage(
            role: message.isUser
                ? AiChatMessageRole.user
                : AiChatMessageRole.assistant,
            content: message.requestText ?? message.text,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161626),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tarot',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, _buildTarotCard),
                  ),
                  const SizedBox(height: 28),
                  if (_activeCardIndex != null) _buildInterpretationCard(),
                  const SizedBox(height: 16),
                  Container(
                    height: 0.5,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  if (_intakeSummary.isNotEmpty) ...[
                    _buildIntakeSummaryCard(),
                    const SizedBox(height: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _chatMessages.map(_buildChatBubble).toList(),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildIntakeSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF24244A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin đã cung cấp',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 8),
          ..._intakeSummary.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF8C42)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🎴 Tarot hôm nay',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Rút 3 lá cho tình yêu',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quá khứ · Hiện tại · Tương lai',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildTarotCard(int index) {
    final isFlipped = _flipped[index];
    final card = _selectedCards[index];
    final isActive = _activeCardIndex == index;

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 95,
        height: 145,
        decoration: BoxDecoration(
          color: isFlipped ? const Color(0xFF24244A) : const Color(0xFF2D2D5E),
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(
              isFlipped
                  ? 'assets/images/tarot/tarot_card_front.png'
                  : 'assets/images/tarot/tarot_card_back.png',
            ),
            fit: BoxFit.cover,
          ),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFF8C42)
                : (isFlipped
                      ? const Color(0xFF4A4A8A).withValues(alpha: 0.5)
                      : const Color(0xFF3B3B7A).withValues(alpha: 0.5)),
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: isFlipped
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _positionLabel(index),
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE5E5FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInterpretationCard() {
    final card = _selectedCards[_activeCardIndex!];
    final position = _positionLabel(_activeCardIndex!).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF24244A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${card.name.toUpperCase()} — $position',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.meaning,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_TarotMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D5E),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/ai_avatars/avatar_tarot.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? const Color(0xFF3F3F7A)
                    : const Color(0xFF24244A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: msg.isUser
                      ? Colors.transparent
                      : const Color(0xFF2D2D5E),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: msg.isUser
                        ? Text(
                            msg.text,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          )
                        : AiMarkdownText(
                            data: msg.text,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          ),
                  ),
                  if (msg.streaming && msg.text.isEmpty) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161626),
        border: Border(top: BorderSide(color: Color(0xFF24244A), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSuggestionChip('Giải nghĩa thêm'),
                  _buildSuggestionChip('Lá tương lai là gì?'),
                  _buildSuggestionChip('Rút lại', isDraw: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextField(
                            key: const Key('tarot_ai_chat_input'),
                            controller: _controller,
                            enabled: !_isSending,
                            onSubmitted: _sendMessage,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Hỏi thêm về lá bài...',
                              hintStyle: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.white30,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('tarot_ai_chat_send'),
                    onTap: _isSending
                        ? null
                        : () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFFFFD700)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, {bool isDraw = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (_isSending) return;
          if (isDraw) {
            _drawCards();
          } else {
            _controller.text = text;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDraw ? const Color(0xFFFF8C42) : const Color(0xFF2D2D5E),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDraw ? const Color(0xFFFF8C42) : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _positionLabel(int index) {
    return index == 0 ? 'Quá khứ' : (index == 1 ? 'Hiện tại' : 'Tương lai');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }
}

class _TarotCardData {
  final String name;
  final String meaning;
  final String emoji;

  _TarotCardData(this.name, this.meaning, this.emoji);
}

class _TarotMessage {
  String text;
  final bool isUser;
  final String? requestText;
  bool streaming;

  _TarotMessage(
    this.text,
    this.isUser, {
    this.requestText,
    this.streaming = false,
  });
}

List<String> _summaryFromArgs(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
