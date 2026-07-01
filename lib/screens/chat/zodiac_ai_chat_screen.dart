import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/ai_markdown_text.dart';

class ZodiacAiChatScreen extends StatefulWidget {
  final AiService? aiService;

  const ZodiacAiChatScreen({super.key, this.aiService});

  @override
  State<ZodiacAiChatScreen> createState() => _ZodiacAiChatScreenState();
}

class _ZodiacAiChatScreenState extends State<ZodiacAiChatScreen> {
  late final AiService _aiService = widget.aiService ?? AiService(ApiClient());
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _sessionId = 'ai-tu-vi-${DateTime.now().millisecondsSinceEpoch}';

  final List<_ZodiacMessage> _messages = [
    _ZodiacMessage(
      'Chào bạn! Mình là AI Bondy. Hãy cho mình biết cung, tuổi hoặc câu hỏi tình duyên bạn muốn xem.',
      false,
    ),
    _ZodiacMessage(
      'Bạn có thể hỏi về tính cách, độ tương hợp, ngày tốt hoặc lá số cơ bản.',
      false,
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isSending) return;

    final assistantMessage = _ZodiacMessage('', false, streaming: true);
    setState(() {
      _isSending = true;
      _messages.add(_ZodiacMessage(message, true));
      _messages.add(assistantMessage);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await for (final event in _aiService.streamChat(
        AiStreamChatRequest(
          messages: _buildRequestMessages(),
          mode: AiChatMode.aiTuVi,
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
              'Mình cần thêm ngày sinh, tuổi hoặc câu hỏi cụ thể để xem chính xác hơn.';
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
    return _messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => AiChatMessage(
            role: message.isUser
                ? AiChatMessageRole.user
                : AiChatMessageRole.assistant,
            content: message.text,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: BondyColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tử vi tình yêu',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildGradientHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8C42)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔮 AI Tử vi',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm hiểu tình duyên',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Dựa trên tuổi, cung và câu hỏi của bạn',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ZodiacMessage msg) {
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
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/ai_avatars/avatar_tuvi.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: msg.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFF4D6D)],
                      )
                    : null,
                color: msg.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: const Color(0xFFFFE5EC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: msg.isUser
                        ? Text(
                            msg.text,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          )
                        : AiMarkdownText(
                            data: msg.text,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: BondyColors.textPrimary,
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFFFE5EC), width: 0.5)),
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
                  _buildSuggestionChip('Nói tiếp về Song Ngư'),
                  _buildSuggestionChip('Tình duyên hôm nay'),
                  _buildSuggestionChip('Có hợp nhau không?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFD6E0)),
                      ),
                      child: TextField(
                        key: const Key('zodiac_ai_chat_input'),
                        controller: _controller,
                        enabled: !_isSending,
                        onSubmitted: _sendMessage,
                        decoration: InputDecoration(
                          hintText: 'Nhắn tin cho AI Bondy...',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 14,
                            color: const Color(0xFFFF9EB5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        style: GoogleFonts.manrope(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('zodiac_ai_chat_send'),
                    onTap: _isSending
                        ? null
                        : () => _sendMessage(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF4D6D)],
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

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _isSending
            ? null
            : () {
                _controller.text = text;
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFD6E0)),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF4D6D),
              ),
            ),
          ),
        ),
      ),
    );
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

class _ZodiacMessage {
  String text;
  final bool isUser;
  bool streaming;

  _ZodiacMessage(this.text, this.isUser, {this.streaming = false});
}
