import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';
import '../../services/chat_service.dart';
import '../../services/chat_realtime_service.dart';
import '../../services/match_service.dart';
import '../../viewmodels/ai/ai_coach_viewmodel.dart';
import '../../viewmodels/ai/ai_quota_viewmodel.dart';
import '../../viewmodels/chat/chat_viewmodel.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';
import '../../widgets/chat/voice_message_bubble.dart';
import '../../widgets/inline_ai_suggestion_panel.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/bondy_error_mapper.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../theme/app_theme.dart';
import '../healing/healing_stitch_style.dart';
import '../../core/ai_prompts_config.dart';
import '../../services/relationship_service.dart';
import '../../services/analytics_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ApiClient _apiClient = ApiClient();
  late final ChatService _chatService = ChatService(_apiClient);
  late final MatchService _matchService = MatchService(_apiClient);
  late final BlockService _blockService = BlockService(_apiClient);
  late final AuthService _authService = AuthService();
  final ChatRealtimeService _realtime = ChatRealtimeService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final RelationshipService _relationshipService = RelationshipService(
    apiClient: _apiClient,
  );

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messageFocusNode = FocusNode();
  final _aiCoachViewModel = AiCoachViewModel();
  final List<ChatMessage> _messages = [];

  bool _didReadArguments = false;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _chatId;
  String? _matchId;
  String? _otherUserId;
  String? _currentUserId;
  String _displayName = 'Bondy user';
  String? _photo;
  Timer? _pollTimer;
  Timer? _typingTimer;
  bool _isTypingSent = false;
  bool _partnerTyping = false;
  bool _wsConnected = false;
  bool _isPartnerOnline = false;
  DateTime? _partnerLastSeenAt;
  bool _isRecording = false;
  bool _showEmojiKeyboard = false;
  bool _showAiPanel = false;
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<ChatRealtimeEvent>? _realtimeSub;

  bool _isMessageRequest = false;
  bool _isInitiator = false;
  bool _chatAccepted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aiCoachViewModel.addListener(_handleAiCoachChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;
    _readRouteArguments();
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _pollMessages();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _realtimeSub?.cancel();
    _realtime.dispose();
    final chatId = _chatId;
    if (chatId != null && _isTypingSent) {
      _chatService.sendTypingIndicator(chatId, isTyping: false);
      _realtime.sendTyping(isTyping: false);
    }
    _audioRecorder.dispose();
    _aiCoachViewModel.removeListener(_handleAiCoachChanged);
    _aiCoachViewModel.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Fallback sync when WebSocket is down
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _pollMessages(),
    );
  }

  Future<void> _connectRealtime(String chatId) async {
    try {
      final token = await _authService.requireAccessToken();
      await _realtime.connect(chatId: chatId, accessToken: token);
      await _realtimeSub?.cancel();
      _realtimeSub = _realtime.events.listen(_handleRealtimeEvent);
      if (mounted) setState(() => _wsConnected = _realtime.isConnected);
    } catch (_) {
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  Future<void> _handleRealtimeEvent(ChatRealtimeEvent event) async {
    if (!mounted) return;
    switch (event.kind) {
      case ChatRealtimeEventKind.message:
        final msg = ChatMessage.fromJson(event.data);
        if (_messages.any((m) => m.id == msg.id)) return;
        setState(() => _messages.add(msg));
        _updateChatSummary(msg);
        _scrollToBottom();
        final chatId = _chatId;
        if (msg.senderId != _currentUserId && !msg.isRead && chatId != null) {
          _chatService
              .markAllAsRead(chatId)
              .then((_) {
                if (mounted) {
                  context.read<ChatViewModel>().clearUnread(chatId);
                }
              })
              .catchError((_) {});
        }
        break;
      case ChatRealtimeEventKind.typing:
        final isTyping = event.data['isTyping'] == true;
        if (event.data['userId']?.toString() == _currentUserId) return;
        setState(() => _partnerTyping = isTyping);
        break;
      case ChatRealtimeEventKind.read:
        final readerId = event.data['readerId']?.toString();
        final allRead = event.data['allRead'] == true;
        if (allRead) {
          if (readerId == _currentUserId) return;
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].senderId == _currentUserId &&
                  !_messages[i].isRead) {
                _messages[i] = ChatMessage(
                  id: _messages[i].id,
                  content: _messages[i].content,
                  senderId: _messages[i].senderId,
                  isRead: true,
                  createdAt: _messages[i].createdAt,
                  messageType: _messages[i].messageType,
                  deliveryStatus: _messages[i].deliveryStatus,
                );
              }
            }
          });
          break;
        }
        final messageId = event.data['messageId']?.toString();
        if (messageId == null) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].id == messageId) {
              _messages[i] = ChatMessage(
                id: _messages[i].id,
                content: _messages[i].content,
                senderId: _messages[i].senderId,
                isRead: true,
                createdAt: _messages[i].createdAt,
                messageType: _messages[i].messageType,
                deliveryStatus: _messages[i].deliveryStatus,
              );
            }
          }
        });
        break;
      case ChatRealtimeEventKind.delivery:
        final messageId = event.data['messageId']?.toString();
        final status = event.data['status']?.toString();
        if (messageId == null || status == null) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].id == messageId) {
              _messages[i] = ChatMessage(
                id: _messages[i].id,
                content: _messages[i].content,
                senderId: _messages[i].senderId,
                isRead: _messages[i].isRead,
                createdAt: _messages[i].createdAt,
                messageType: _messages[i].messageType,
                deliveryStatus: status,
              );
            }
          }
        });
        break;
      case ChatRealtimeEventKind.presence:
        final eventUserId = event.data['userId']?.toString();
        if (eventUserId == _currentUserId) return;
        final isOnline = event.data['isOnline'] == true;
        final lastSeenRaw = event.data['lastSeenAt']?.toString();
        final lastSeen = lastSeenRaw != null
            ? DateTime.tryParse(lastSeenRaw)
            : null;
        setState(() {
          _isPartnerOnline = isOnline;
          _partnerLastSeenAt = lastSeen ?? _partnerLastSeenAt;
        });
        final chatId = _chatId;
        if (chatId != null) {
          context.read<ChatViewModel>().updatePartnerPresence(
            chatId: chatId,
            isOnline: isOnline,
            lastSeenAt: lastSeenRaw,
          );
        }
        break;
      case ChatRealtimeEventKind.connected:
        setState(() => _wsConnected = true);
        break;
      case ChatRealtimeEventKind.relationshipInvited:
        final eventMatchId = event.data['matchId']?.toString();
        if (eventMatchId != null && eventMatchId != _matchId) return;
        final invitationData = event.data['invitation'];
        if (invitationData is! Map<String, dynamic>) return;
        final invitation = RelationshipInvitation.fromJson(invitationData);
        if (invitation.inviterId == _currentUserId) {
          setState(() {
            _sentPendingInvite = true;
            _pendingInvite = invitation.toJson();
          });
          return;
        }
        setState(() {
          _sentPendingInvite = false;
          _pendingInvite = invitation.toJson();
          _showCollapsedBanner = false;
        });
        _showInviteDialog();
        break;
      case ChatRealtimeEventKind.relationshipAccepted:
        final systemMsgData = event.data['systemMessage'];
        if (systemMsgData is Map<String, dynamic>) {
          final systemMsg = ChatMessage.fromJson(systemMsgData);
          if (!_messages.any((m) => m.id == systemMsg.id)) {
            setState(() {
              _messages.add(systemMsg);
            });
            _updateChatSummary(systemMsg);
            _scrollToBottom();
          }
        }
        setState(() {
          _showCollapsedBanner = false;
          _pendingInvite = null;
          _sentPendingInvite = false;
          _hasRelationship = true;
        });
        await context.read<RelationshipViewModel>().loadDashboard();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/relationship/established',
          (route) => false,
          arguments: {'name': _displayName, 'photo': _photo},
        );
        break;
      case ChatRealtimeEventKind.chatAccepted:
        setState(() {
          _chatAccepted = true;
          _isMessageRequest = false;
        });
        final systemMsgData = event.data['systemMessage'];
        if (systemMsgData is Map<String, dynamic>) {
          final systemMsg = ChatMessage.fromJson(systemMsgData);
          if (!_messages.any((m) => m.id == systemMsg.id)) {
            setState(() {
              _messages.add(systemMsg);
            });
            _updateChatSummary(systemMsg);
            _scrollToBottom();
          }
        }
        break;
      case ChatRealtimeEventKind.relationshipInviteCanceled:
        final eventMatchId = event.data['matchId']?.toString();
        if (eventMatchId != null && eventMatchId != _matchId) return;
        setState(() {
          _pendingInvite = null;
          _sentPendingInvite = false;
          _showCollapsedBanner = false;
        });
        BondyFeedback.showSuccess(
          context,
          'Lời mời xác nhận mối quan hệ đã bị hủy.',
        );
        break;
    }
  }

  Map<String, dynamic>? _pendingInvite;
  bool _showCollapsedBanner = false;
  bool _hasRelationship = false;
  bool _sentPendingInvite = false;

  Future<void> _checkPendingInvite() async {
    final matchId = _matchId;
    if (matchId == null) return;
    try {
      final result = await _relationshipService.checkPendingInvite(matchId);
      if (!mounted) return;
      if (result['invitation'] != null) {
        final invitation = RelationshipInvitation.fromJson(
          result['invitation'] as Map<String, dynamic>,
        );
        if (invitation.inviterId == _currentUserId) {
          setState(() {
            _sentPendingInvite = true;
            _pendingInvite = invitation.toJson();
          });
        } else {
          setState(() {
            _sentPendingInvite = false;
            _pendingInvite = invitation.toJson();
          });
          _showInviteDialog();
        }
      } else {
        setState(() {
          _sentPendingInvite = false;
          _pendingInvite = null;
        });
      }
    } catch (_) {}
  }

  void _showInviteDialog() {
    final invite = _pendingInvite;
    if (invite == null) return;

    final inviterName = invite['inviterName']?.toString() ?? 'Người dùng';
    final inviterPhoto = invite['inviterPhoto']?.toString();
    final matchId = _matchId;
    if (matchId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFFFFFAF8),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: BondyColors.textSecondary,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _showCollapsedBanner = true;
                      });
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      (inviterPhoto != null && inviterPhoto.startsWith('http'))
                      ? NetworkImage(inviterPhoto)
                      : null,
                  child:
                      (inviterPhoto == null || !inviterPhoto.startsWith('http'))
                      ? const Icon(
                          Icons.person,
                          size: 36,
                          color: BondyColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lời mời xác nhận mối quan hệ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$inviterName muốn xác nhận mối quan hệ với bạn.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: BondyColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _declineInvite();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: Text(
                          'Từ chối',
                          style: GoogleFonts.plusJakartaSans(
                            color: BondyColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: BondyColors.primaryGradient,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: BondyColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _acceptInvite();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Text(
                            'Đồng ý ❤️',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptInvite() async {
    final matchId = _matchId;
    if (matchId == null) return;
    try {
      final res = await _relationshipService.acceptByMatchId(matchId);
      if (!mounted) return;
      setState(() {
        _showCollapsedBanner = false;
        _pendingInvite = null;
      });
      if (res['systemMessage'] != null) {
        final systemMsg = ChatMessage.fromJson(
          res['systemMessage'] as Map<String, dynamic>,
        );
        if (!_messages.any((m) => m.id == systemMsg.id)) {
          setState(() {
            _messages.add(systemMsg);
          });
          _updateChatSummary(systemMsg);
          _scrollToBottom();
        }
      }
      setState(() {
        _hasRelationship = true;
      });
      await context.read<RelationshipViewModel>().loadDashboard();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/relationship/established',
        (route) => false,
        arguments: {'name': _displayName, 'photo': _photo},
      );
    } catch (e) {
      if (mounted) {
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không chấp nhận được lời mời.',
        );
      }
    }
  }

  Future<void> _declineInvite() async {
    final matchId = _matchId;
    if (matchId == null) return;
    try {
      await _relationshipService.declineInvite(matchId);
      if (!mounted) return;
      setState(() {
        _showCollapsedBanner = false;
        _pendingInvite = null;
      });
      BondyFeedback.showSuccess(context, 'Đã từ chối lời mời.');
    } catch (e) {
      if (mounted) {
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không từ chối được lời mời.',
        );
      }
    }
  }

  Widget _buildCollapsedBanner() {
    final invite = _pendingInvite;
    if (!_showCollapsedBanner || invite == null) {
      return const SizedBox.shrink();
    }
    final inviterName = invite['inviterName']?.toString() ?? 'Người dùng';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showCollapsedBanner ? 48 : 0,
      child: Container(
        color: const Color(0xFFFFF0F5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.favorite_border,
              size: 16,
              color: BondyColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lời mời xác nhận mối quan hệ từ $inviterName',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _acceptInvite,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Đồng ý',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: BondyColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _showCollapsedBanner = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkRelationshipStatus() async {
    try {
      final dash = await _relationshipService.getDashboard();
      if (mounted) {
        setState(() {
          _hasRelationship =
              dash.hasRelationship && dash.partnerId == _otherUserId;
        });
      }
    } catch (_) {}
  }

  Widget _buildRelationshipStatusIndicator() {
    if (!_hasRelationship && _pendingInvite == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: HealingStitchColors.warmBackground,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: InkWell(
        onTap: () {
          if (_hasRelationship) {
            Navigator.pushNamed(context, '/relationship/home');
          } else if (_sentPendingInvite) {
            _showPendingInvitationBottomSheet();
          } else if (_pendingInvite != null) {
            _showInviteDialog();
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [healingSoftShadow(0.02)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: _hasRelationship
                    ? Colors.pinkAccent
                    : (_sentPendingInvite ? Colors.orange : Colors.grey),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _hasRelationship
                    ? 'Đã xác nhận mối quan hệ'
                    : (_sentPendingInvite
                          ? 'Đang chờ phản hồi'
                          : 'Xác nhận mối quan hệ'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HealingStitchColors.textMain,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvitationBottomSheet() {
    if (_sentPendingInvite) {
      _showPendingInvitationBottomSheet();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCsgnYy8VW20CiYCVCqg8zVPiFE7qcVqSprT2bF4XVJHKShNuiZH4QvrSimg7ny5ofI1wWBMphBWGyCJiUUlCrwbfAHTcSo8XxION3MupzLDXLWzecVzCoTZGh3diOCqobJDjMkUh9Al1LTTSC4Ykd1BYxeDdHKqf-tzCT6SBTKAph-g5f0YldSABwVsW37Rmpz-oeeu8wgBttoAfisoCHmhmxONpBBjdzprzcIs2s3LZD_eJ7rgUtTBw6EqgyC9nHAdhSSKTmjAdd6',
                          ),
                        ),
                      ),
                      const SizedBox(width: -12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage:
                              _photo != null && _photo!.startsWith('http')
                              ? NetworkImage(_photo!)
                              : const NetworkImage(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDLFtkpJawOulzk07g6ONeRHHCNIyJrGyaF73PQyJrva98w8x4CgZE-4Aa_AA82hxzO6qpGwV7PsXoeQr4K_gJFP9dBMogVYmjiEULvLdcJQpdWXh-02TVqgontL8ili4xvUIFWYv3XK8qpqJGA76NzO2P2SsaRg09JtfRhFcPS3feVxEGf6F-Xd_vTs18RC4bDkD9a1-LV-TLRR7IGYuoLHu58h3JV3Qf7CtQwkPmVLOJa1UGXTizsnldFaC7dVqxAzb8eCWvTa9lx',
                                    )
                                    as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEE2B5B), Color(0xFFFF6B6B)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bạn muốn xác nhận\nmối quan hệ này?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HealingStitchColors.textMain,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Gửi lời mời đến $_displayName để chính thức xác nhận và mở khóa các tính năng dành riêng cho cặp đôi trên Bondy.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: HealingStitchColors.textSoft,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEE2B5B), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEE2B5B).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _sendRelationshipInvite();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Gửi lời mời',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Để sau nhé',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HealingStitchColors.textSoft,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Mở khóa Bondy Love Space',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: HealingStitchColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendRelationshipInvite() async {
    final matchId = _matchId;
    if (matchId == null) {
      BondyFeedback.showError(
        context,
        'Không tìm thấy thông tin match để gửi lời mời.',
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final result = await _relationshipService.createInvite(matchId: matchId);
      if (!mounted) return;
      setState(() {
        _sentPendingInvite = true;
        _pendingInvite = result;
      });
      BondyFeedback.showSuccess(
        context,
        'Đã gửi lời mời xác nhận mối quan hệ đến $_displayName!',
      );
    } catch (e) {
      if (mounted) {
        final msg = BondyErrorMapper.message(e);
        if (msg.contains('đang hoạt động') ||
            msg.contains('đang chờ phản hồi') ||
            msg.contains('đã có một mối quan hệ') ||
            msg.contains('đã xác nhận mối quan hệ') ||
            msg.contains('đang chờ cho kết nối này')) {
          await _showRelationshipRuleDialog(msg);
        } else {
          BondyFeedback.showError(
            context,
            e,
            fallback: 'Không gửi được lời mời.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showPendingInvitationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCsgnYy8VW20CiYCVCqg8zVPiFE7qcVqSprT2bF4XVJHKShNuiZH4QvrSimg7ny5ofI1wWBMphBWGyCJiUUlCrwbfAHTcSo8XxION3MupzLDXLWzecVzCoTZGh3diOCqobJDjMkUh9Al1LTTSC4Ykd1BYxeDdHKqf-tzCT6SBTKAph-g5f0YldSABwVsW37Rmpz-oeeu8wgBttoAfisoCHmhmxONpBBjdzprzcIs2s3LZD_eJ7rgUtTBw6EqgyC9nHAdhSSKTmjAdd6',
                          ),
                        ),
                      ),
                      const SizedBox(width: -12),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage:
                              _photo != null && _photo!.startsWith('http')
                              ? NetworkImage(_photo!)
                              : const NetworkImage(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDLFtkpJawOulzk07g6ONeRHHCNIyJrGyaF73PQyJrva98w8x4CgZE-4Aa_AA82hxzO6qpGwV7PsXoeQr4K_gJFP9dBMogVYmjiEULvLdcJQpdWXh-02TVqgontL8ili4xvUIFWYv3XK8qpqJGA76NzO2P2SsaRg09JtfRhFcPS3feVxEGf6F-Xd_vTs18RC4bDkD9a1-LV-TLRR7IGYuoLHu58h3JV3Qf7CtQwkPmVLOJa1UGXTizsnldFaC7dVqxAzb8eCWvTa9lx',
                                    )
                                    as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.hourglass_empty,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Đang chờ xác nhận',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HealingStitchColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lời mời xác nhận mối quan hệ đã được gửi đến $_displayName và đang chờ đối phương đồng ý.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: HealingStitchColors.textSoft,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _cancelRelationshipInvite();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.close,
                        color: HealingStitchColors.textMain,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rút lời mời',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: HealingStitchColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HealingStitchColors.textSoft,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelRelationshipInvite() async {
    final matchId = _matchId;
    if (matchId == null) return;
    setState(() => _isSending = true);
    try {
      await _relationshipService.cancelInvite(matchId);
      if (!mounted) return;
      setState(() {
        _sentPendingInvite = false;
        _pendingInvite = null;
      });
      BondyFeedback.showSuccess(
        context,
        'Đã rút lời mời xác nhận mối quan hệ!',
      );
    } catch (e) {
      if (mounted) {
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không rút được lời mời.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pollMessages() async {
    final chatId = _chatId;
    if (chatId == null || _isLoading || _isSending) return;
    try {
      final messages = await _chatService.listMessages(chatId);
      if (!mounted) return;
      final existingIds = _messages.map((m) => m.id).toSet();
      final added = messages.where((m) => !existingIds.contains(m.id)).toList();
      if (added.isEmpty) return;
      setState(() => _messages.addAll(added));
      for (final message in added) {
        _updateChatSummary(message);
      }
      _scrollToBottom();
      final hasIncoming = added.any(
        (m) => m.senderId != _currentUserId && !m.isRead,
      );
      if (hasIncoming) {
        await _chatService.markAllAsRead(chatId);
        if (mounted) {
          context.read<ChatViewModel>().clearUnread(chatId);
        }
      }
      if (!_wsConnected) {
        final typing = await _chatService.fetchPartnerTyping(chatId);
        if (mounted && typing != _partnerTyping) {
          setState(() => _partnerTyping = typing);
        }
      }
    } catch (error, stackTrace) {
      // F-02 fix: log poll errors instead of silently swallowing them so a
      // broken realtime + poll fallback is at least visible in debug builds.
      debugPrint('chat:poll-error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace, maxFrames: 4);
    }
  }

  Future<void> _pickAndSendImage() async {
    final chatId = _chatId;
    if (chatId == null || _isSending) return;

    // image_picker (gallery) dùng Photo Picker (Android 13+) / PHPicker (iOS) /
    // <input type=file> (web) — các picker này chạy ngoài tiến trình app nên
    // KHÔNG cần xin quyền runtime. Gọi Permission.photos.request() trước đây
    // chặn nhầm: web không hỗ trợ, Android ≤12 không có READ_MEDIA_IMAGES, iOS
    // báo denied/crash khi thiếu usage description → ảnh không gửi được. Bỏ
    // gate, để chính picker quản lý quyền truy cập.
    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      if (_isChatNotAcceptedError(e)) {
        await _hydrateChatMetadata();
        if (!mounted) return;
      }
      BondyFeedback.showError(
        context,
        e,
        fallback: 'Không mở được thư viện ảnh.',
      );
      return;
    }
    if (picked == null) return;
    setState(() => _isSending = true);
    try {
      final message = await _chatService.sendImageMessage(chatId, picked);
      if (!mounted) return;
      setState(() => _messages.add(message));
      _updateChatSummary(message);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e, fallback: 'Không gửi được ảnh.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _readRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _chatId = args['chatId'] as String?;
      _matchId = args['matchId'] as String?;
      _otherUserId = args['otherUserId'] as String?;
      _displayName = (args['name'] as String?)?.trim().isNotEmpty == true
          ? args['name'] as String
          : _displayName;
      _photo = args['photo'] as String?;
      _isPartnerOnline = args['isOnline'] as bool? ?? false;
      final rawLastSeen = args['lastSeenAt'] as String?;
      if (rawLastSeen != null) {
        _partnerLastSeenAt = DateTime.tryParse(rawLastSeen);
      }
      _isMessageRequest = args['isMessageRequest'] as bool? ?? false;
      _isInitiator = args['isInitiator'] as bool? ?? false;
      _chatAccepted =
          args['chatAccepted'] as bool? ?? !(_isMessageRequest || _isInitiator);
    } else if (args is String) {
      _chatId = args;
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentUserId = await _authService.getCurrentUserId();
      await _hydrateChatMetadata();
      final chatIdForAnalytics = _chatId;
      if (chatIdForAnalytics != null) {
        analytics.chatOpened(chatIdForAnalytics);
      }
      await _loadMessages();
      final chatId = _chatId;
      if (chatId != null) {
        // Bulk mark-as-read on entering the room (single API call instead of
        // one PUT per message). Backend broadcasts a 'read allRead' event so
        // the other side flips ticks in one shot.
        try {
          await _chatService.markAllAsRead(chatId);
          if (mounted) {
            context.read<ChatViewModel>().clearUnread(chatId);
          }
        } catch (_) {}
        // Fetch presence snapshot once — WebSocket presence events keep it
        // fresh after this.
        try {
          final presence = await _chatService.fetchPartnerPresence(chatId);
          if (mounted) {
            setState(() {
              _isPartnerOnline = presence.isOnline;
              final raw = presence.lastSeenAt;
              if (raw != null) _partnerLastSeenAt = DateTime.tryParse(raw);
            });
          }
        } catch (_) {}
        await _connectRealtime(chatId);
      }
      _startPolling();
      _checkPendingInvite();
      _checkRelationshipStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _hydrateChatMetadata() async {
    if (_chatId == null) return;

    final chats = await _chatService.listChats();
    if (!mounted) return;
    for (final chat in chats) {
      if (chat.id != _chatId) continue;
      setState(() {
        _matchId = chat.matchId;
        _otherUserId = chat.otherUser.id;
        final name = chat.otherUser.displayName;
        if (name.isNotEmpty) _displayName = name;
        _photo = chat.otherUser.photo;
        _chatAccepted = chat.chatAccepted;
        _isMessageRequest = chat.isMessageRequest;
        _isInitiator = chat.isInitiator;
      });
      break;
    }
  }

  Future<void> _loadMessages() async {
    final chatId = _chatId;
    if (chatId == null) {
      throw StateError('Missing chat ID');
    }

    final messages = await _chatService.listMessages(chatId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
    });
    _scrollToBottom();
  }

  void _onTextChanged(String value) {
    final chatId = _chatId;
    if (chatId == null) return;
    _typingTimer?.cancel();
    if (value.trim().isEmpty) {
      if (_isTypingSent) {
        _isTypingSent = false;
        _chatService.sendTypingIndicator(chatId, isTyping: false);
      }
      return;
    }
    _typingTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!_isTypingSent) {
        _isTypingSent = true;
        _realtime.sendTyping(isTyping: true);
        await _chatService.sendTypingIndicator(chatId, isTyping: true);
      }
    });
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      String? path;
      try {
        path = await _audioRecorder.stop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isRecording = false);
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không dừng được ghi âm.',
        );
        return;
      }
      setState(() => _isRecording = false);
      final chatId = _chatId;
      if (path == null || chatId == null) {
        if (mounted) {
          BondyFeedback.showError(
            context,
            Exception('Không lưu được file ghi âm.'),
          );
        }
        return;
      }
      setState(() => _isSending = true);
      try {
        final message = await _chatService.sendVoiceMessage(chatId, path);
        if (!mounted) return;
        setState(() => _messages.add(message));
        _updateChatSummary(message);
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          e,
          fallback: 'Không gửi được tin nhắn thoại.',
        );
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      return;
    }

    // Dùng API hasPermission của record plugin (đồng bộ với native), tránh
    // tình huống permission_handler báo granted nhưng record vẫn từ chối trên
    // một số ROM. Nếu plugin báo chưa có thì mới rơi xuống permission_handler.
    final pluginPermission = await _audioRecorder.hasPermission();
    if (!pluginPermission) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          Exception('Cần quyền micro để ghi âm tin nhắn thoại.'),
        );
        return;
      }
    }

    try {
      // Web không hỗ trợ ghi ra file path (path_provider không có web impl) →
      // truyền path rỗng, plugin record sẽ ghi vào blob và trả URL khi stop().
      String path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      // aacLc không được hỗ trợ trên web → fallback sang opus. Trên native vẫn
      // ưu tiên aacLc cho file .m4a gọn nhẹ, mở được ở mọi nơi.
      var encoder = AudioEncoder.aacLc;
      if (!await _audioRecorder.isEncoderSupported(encoder)) {
        encoder = AudioEncoder.opus;
      }
      await _audioRecorder.start(RecordConfig(encoder: encoder), path: path);
      // start() có thể return TRƯỚC khi recorder native kịp chuyển sang trạng
      // thái recording (nhất là ngay sau hộp thoại xin quyền) → kiểm tra
      // isRecording() ngay lập tức hay trả false → báo lỗi nhầm "không bắt được
      // ghi âm" dù mic vẫn hoạt động. Đợi một nhịp ngắn trước khi xác nhận.
      await Future.delayed(const Duration(milliseconds: 350));
      // Xác nhận recorder thật sự đang chạy — bắt trường hợp nhà sản xuất chặn
      // ngầm (ví dụ Xiaomi MIUI auto-deny) thay vì để user bấm stop ra file rỗng.
      final actuallyRecording = await _audioRecorder.isRecording();
      if (!actuallyRecording) {
        if (!mounted) return;
        BondyFeedback.showError(
          context,
          Exception('Không khởi động được micro. Kiểm tra quyền hoặc thử lại.'),
        );
        return;
      }
      setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(
        context,
        e,
        fallback: 'Không bắt đầu được ghi âm.',
      );
    }
  }

  Future<void> _sendMessage([String? preset]) async {
    final chatId = _chatId;
    final content = (preset ?? _controller.text).trim();
    if (chatId == null || content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await _chatService.sendMessage(chatId, content);
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        if (preset == null) _controller.clear();
      });
      _updateChatSummary(message);
      final msgChatId = _chatId;
      if (msgChatId != null) {
        analytics.messageSent(msgChatId, preset != null ? 'preset' : 'text');
      }
      _scrollToBottom();
      try {
        await _chatService.updateDeliveryStatus(message.id, 'DELIVERED');
      } catch (e) {
        debugPrint('[CHAT-DBG] Không thể cập nhật trạng thái đã nhận: $e');
      }
      if (_isTypingSent) {
        _isTypingSent = false;
        await _chatService.sendTypingIndicator(chatId, isTyping: false);
      }
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(
        context,
        e,
        fallback: 'Không thể gửi tin nhắn. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isChatNotAcceptedError(Object error) {
    final message = error is ApiClientException
        ? error.message
        : BondyErrorMapper.message(error);
    final lower = message.toLowerCase();
    return lower.contains('chưa được chấp nhận') ||
        lower.contains('chua duoc chap nhan');
  }

  void _updateChatSummary(ChatMessage message) {
    final chatId = _chatId;
    final currentUserId = _currentUserId;
    if (chatId == null || currentUserId == null) return;
    context.read<ChatViewModel>().updateLatestMessage(
      chatId: chatId,
      message: message,
      currentUserId: currentUserId,
    );
  }

  void _handleAiCoachChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleAiSuggestions() async {
    if (_showAiPanel) {
      _aiCoachViewModel.cancelPendingRequest();
      setState(() => _showAiPanel = false);
      return;
    }

    await _hydrateChatMetadata();
    if (!mounted) return;

    final matchId = _matchId;
    final chatId = _chatId;
    final partnerId = _otherUserId;
    if (matchId == null ||
        matchId.trim().isEmpty ||
        chatId == null ||
        chatId.trim().isEmpty ||
        partnerId == null ||
        partnerId.trim().isEmpty) {
      BondyFeedback.showError(
        context,
        'Không tìm thấy đủ thông tin cuộc trò chuyện để Bondy gợi ý tin nhắn.',
      );
      return;
    }

    _aiCoachViewModel.reset();
    setState(() {
      _showAiPanel = true;
      _showEmojiKeyboard = false;
    });
  }

  Future<void> _loadAiSuggestions({AiIntent? intent}) async {
    final matchId = _matchId;
    final chatId = _chatId;
    final partnerId = _otherUserId;
    if (matchId == null ||
        matchId.trim().isEmpty ||
        chatId == null ||
        chatId.trim().isEmpty ||
        partnerId == null ||
        partnerId.trim().isEmpty) {
      return;
    }

    if (intent != null) {
      _aiCoachViewModel.selectIntent(intent);
    }
    if (_aiCoachViewModel.selectedIntent == null) {
      return;
    }
    final quotaViewModel = context.read<AiQuotaViewModel>();
    final currentQuota = quotaViewModel.quotaFor(AiChatMode.coach);
    _aiCoachViewModel.setQuota(currentQuota);
    if (currentQuota != null && currentQuota.remaining <= 0) {
      await _showAiQuotaUpgradeDialog(
        quota: currentQuota,
        modal: _aiCoachViewModel.upgradeModal,
      );
      return;
    }
    await _aiCoachViewModel.getPersonalizedSuggestions(
      chatId: chatId,
      matchId: matchId,
      expectedPartnerId: partnerId,
    );
    final updatedQuota = _aiCoachViewModel.quota;
    if (updatedQuota != null) {
      quotaViewModel.applyQuota(updatedQuota);
    }
    if (_aiCoachViewModel.isLimitReached) {
      await _showAiQuotaUpgradeDialog(
        quota: _aiCoachViewModel.quota,
        modal: _aiCoachViewModel.upgradeModal,
      );
    }
  }

  Future<void> _applyAiSuggestion(String suggestion) async {
    final currentDraft = _controller.text.trim();
    if (currentDraft.isNotEmpty && currentDraft != suggestion.trim()) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Thay nội dung đang nhập?'),
          content: const Text(
            'Gợi ý AI sẽ thay draft hiện tại. Bạn vẫn có thể chỉnh sửa trước khi gửi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Giữ draft'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Dùng gợi ý'),
            ),
          ],
        ),
      );
      if (shouldReplace != true || !mounted) return;
    }

    setState(() {
      _controller.text = suggestion;
      _controller.selection = TextSelection.collapsed(
        offset: suggestion.length,
      );
      _showAiPanel = false;
      _showEmojiKeyboard = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    });
  }

  Future<void> _showAiQuotaUpgradeDialog({
    AiModeQuota? quota,
    AiQuotaUpgradeModal? modal,
  }) async {
    final title = modal?.title ?? 'Bạn đã hết lượt AI hôm nay';
    final message =
        modal?.message ??
        'Gợi ý trò chuyện sẽ được làm mới vào ngày mai. Nâng cấp subscription để có thêm lượt mỗi ngày.';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(
          quota == null
              ? message
              : '$message\n\nHiện tại: ${quota.remaining}/${quota.limit} lượt.',
          style: GoogleFonts.plusJakartaSans(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(modal?.secondaryCtaLabel ?? 'Để sau'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Navigator.of(context).pushNamed('/settings/premium');
              if (mounted) {
                await context.read<AiQuotaViewModel>().loadQuota();
              }
            },
            child: Text(modal?.ctaLabel ?? 'Xem gói subscription'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _isLoading
              ? null
              : () {
                  Navigator.pushNamed(
                    context,
                    '/chat/info',
                    arguments: {
                      'matchId': _matchId,
                      'otherUserId': _otherUserId,
                      'name': _displayName,
                      'photo': _photo,
                    },
                  );
                },
          child: Row(
            children: [
              _buildAvatar(_photo, _displayName, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    _buildPresenceSubtitle(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            key: const Key('more_options_button'),
            onPressed: _isLoading ? null : () => _showMoreOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRelationshipStatusIndicator(),
          _buildCollapsedBanner(),
          if (!_chatAccepted && _isMessageRequest) _buildMessageRequestBanner(),
          if (!_chatAccepted && _isInitiator) _buildWaitingAcceptanceBanner(),
          Expanded(child: _buildMessagesBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageRequestBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F3FF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '💌 $_displayName muốn nhắn tin cho bạn. Chấp nhận để trò chuyện nhé!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5B21B6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final matchId = _matchId;
                  if (matchId == null) return;
                  try {
                    await _chatService.acceptChat(matchId);
                    setState(() {
                      _chatAccepted = true;
                      _isMessageRequest = false;
                    });
                    unawaited(context.read<ChatViewModel>().fetchChats());
                  } catch (e) {
                    BondyFeedback.showError(context, 'Lỗi chấp nhận: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(130, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Chấp nhận 💬',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  final matchId = _matchId;
                  if (matchId == null) return;
                  try {
                    await _chatService.declineChat(matchId);
                    unawaited(context.read<ChatViewModel>().fetchChats());
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    BondyFeedback.showError(context, 'Lỗi từ chối: $e');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  minimumSize: const Size(130, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Từ chối',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingAcceptanceBanner() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      alignment: Alignment.center,
      child: Text(
        '⏳ Đang chờ đối phương chấp nhận cuộc trò chuyện...',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildMessagesBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BondyErrorBanner(message: _errorMessage!, onRetry: _bootstrap),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Hãy bắt đầu bằng một lời chào nhé.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: BondyColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildBubble(_messages[index]),
    );
  }

  Widget _buildInputBar() {
    final bool isReceiverUnaccepted = _isMessageRequest && !_chatAccepted;
    final int sentCount = _messages.where((m) => m.senderId == _currentUserId).length;
    final bool isInitiatorLimitReached = _isInitiator && !_chatAccepted && sentCount >= 3;
    final bool isInputBarDisabled = isReceiverUnaccepted || isInitiatorLimitReached;

    final coachQuota = context.watch<AiQuotaViewModel>().quotaFor(
      AiChatMode.coach,
    );
    final aiSuggestionLabel = coachQuota == null
        ? 'AI gợi ý nhắn tin'
        : 'AI gợi ý (${coachQuota.remaining}/${coachQuota.limit})';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: BondyColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isInputBarDisabled)
              SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AIPromptsConfig.deeperPrompts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: BondyColors.primary,
                        ),
                        label: Text(
                          aiSuggestionLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BondyColors.textPrimary,
                          ),
                        ),
                        backgroundColor: const Color(0xFFFFF1EE),
                        side: BorderSide(
                          color: BondyColors.primary.withValues(alpha: 0.28),
                        ),
                        onPressed: _isSending || _isLoading
                            ? null
                            : _toggleAiSuggestions,
                      ),
                    );
                  }
                  final prompt = AIPromptsConfig.deeperPrompts[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.psychology,
                        size: 16,
                        color: BondyColors.primary,
                      ),
                      label: Text(
                        prompt,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: BondyColors.primary.withValues(alpha: 0.2),
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.text = prompt;
                        });
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (_showAiPanel)
              InlineAiSuggestionPanel(
                viewModel: _aiCoachViewModel,
                partnerName: _displayName,
                onClose: () {
                  _aiCoachViewModel.cancelPendingRequest();
                  setState(() => _showAiPanel = false);
                },
                onRetry: _loadAiSuggestions,
                onGenerate: _loadAiSuggestions,
                onIntentSelected: _aiCoachViewModel.selectIntent,
                onSuggestionSelected: _applyAiSuggestion,
              ),
            const SizedBox(height: 8),
            if (_showEmojiKeyboard) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                        '❤️',
                        '😂',
                        '👍',
                        '😍',
                        '🔥',
                        '😭',
                        '😮',
                        '👏',
                        '🎉',
                        '✨',
                        '🙌',
                        '💯',
                        '🤣',
                        '🤔',
                        '🙏',
                        '🌸',
                        '☕',
                        '🍕',
                        '🍰',
                        '🎈',
                      ].map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              final text = _controller.text;
                              final selection = _controller.selection;
                              int start = selection.start;
                              int end = selection.end;
                              if (start < 0 || end < 0) {
                                start = text.length;
                                end = text.length;
                              }
                              final newText = text.replaceRange(
                                start,
                                end,
                                emoji,
                              );
                              _controller.text = newText;
                              _controller.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(offset: start + emoji.length),
                                  );
                              setState(() {});
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: (_isSending || isInputBarDisabled) ? null : _pickAndSendImage,
                  icon: const Icon(Icons.image_outlined),
                ),
                IconButton(
                  onPressed: (_isSending || isInputBarDisabled) ? null : _toggleVoiceRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic_none,
                    color: _isRecording ? Colors.red : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('message_input'),
                    controller: _controller,
                    focusNode: _messageFocusNode,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) {
                      setState(() {});
                      _onTextChanged(value);
                    },
                    onTap: () {
                      if (_showEmojiKeyboard) {
                        setState(() {
                          _showEmojiKeyboard = false;
                        });
                      }
                    },
                    onSubmitted: (_) {
                      if (!isInputBarDisabled) _sendMessage();
                    },
                    enabled: !_isSending && _chatId != null && !isInputBarDisabled,
                    decoration: InputDecoration(
                      hintText: isReceiverUnaccepted
                          ? '🔒 Chấp nhận để trả lời'
                          : (isInitiatorLimitReached
                              ? '⏳ Chờ chấp nhận...'
                              : 'Nhập tin nhắn...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: BondyColors.textHint,
                      ),
                      filled: true,
                      fillColor: BondyColors.background,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showEmojiKeyboard
                              ? Icons.keyboard_alt_outlined
                              : Icons.sentiment_satisfied_alt_outlined,
                          color: BondyColors.primary,
                        ),
                        onPressed: isInputBarDisabled
                            ? null
                            : () {
                                setState(() {
                                  _showEmojiKeyboard = !_showEmojiKeyboard;
                                });
                              },
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('send_button'),
                  onPressed: _controller.text.trim().isEmpty || _isSending || isInputBarDisabled
                      ? null
                      : () {
                          _sendMessage();
                        },
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    // ── Tin nhắn hệ thống (SYSTEM) — hiển thị giữa, không dạng bubble ──
    if (msg.messageType == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF5F3), Color(0xFFFFF0F5)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              msg.content,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEA2A5A),
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    final isMine = msg.senderId == _currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        key: const Key('chat_bubble'),
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildAvatar(_photo, _displayName, radius: 14),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF97316), Color(0xFFEA2A5A)],
                      )
                    : null,
                color: isMine ? null : const Color(0xFFFFF1EE),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.messageType == 'IMAGE' &&
                      msg.content.startsWith('http'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg.content,
                        height: 180,
                        width: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image),
                      ),
                    )
                  else if (msg.messageType == 'VOICE' &&
                      msg.content.startsWith('http'))
                    VoiceMessageBubble(audioUrl: msg.content, isMine: isMine)
                  else
                    Text(
                      msg.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: msg.messageType == 'EMOJI' ? 28 : 14,
                        color: isMine ? Colors.white : BondyColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : BondyColors.textHint,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead
                              ? Icons.done_all
                              : (msg.deliveryStatus == 'DELIVERED'
                                    ? Icons.done_all
                                    : Icons.done),
                          size: 12,
                          color: msg.isRead
                              ? Colors.lightBlueAccent
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    String? photo,
    String displayName, {
    required double radius,
  }) {
    if (photo != null && photo.startsWith('http')) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photo));
    }

    final initial = displayName.trim().isEmpty
        ? 'B'
        : displayName.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: BondyColors.primaryLight,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showMoreOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFFF6B6B)),
              title: const Text('Thông tin'),
              subtitle: const Text('Xem thông tin & xác nhận mối quan hệ'),
              onTap: () => Navigator.pop(context, 'info'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Bỏ kết nối'),
              onTap: () => Navigator.pop(context, 'unmatch'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Chặn người dùng'),
              onTap: () => Navigator.pop(context, 'block'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (result == 'info') {
      Navigator.pushNamed(
        context,
        '/chat/info',
        arguments: {
          'matchId': _matchId,
          'otherUserId': _otherUserId,
          'name': _displayName,
          'photo': _photo,
        },
      );
    } else if (result == 'unmatch') {
      await _confirmUnmatch(context);
    } else if (result == 'block') {
      await _confirmBlock(context);
    }
  }

  Future<void> _confirmUnmatch(BuildContext context) async {
    final confirmed = await _confirmDangerAction(
      context,
      title: 'Xác nhận bỏ kết nối?',
      content: 'Tin nhắn sẽ được ẩn với người này.',
      action: 'Bỏ kết nối',
    );
    if (confirmed != true) return;

    await _hydrateChatMetadata();
    final matchId = _matchId;
    if (matchId == null) {
      _showSnackBar('Không tìm thấy match để bỏ kết nối.');
      return;
    }

    await _runRelationshipAction(() => _matchService.unmatch(matchId));
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await _confirmDangerAction(
      context,
      title: 'Xác nhận chặn người dùng?',
      content: 'Người này sẽ không thể thấy hoặc nhắn tin với bạn.',
      action: 'Chặn',
    );
    if (confirmed != true) return;

    await _hydrateChatMetadata();
    final blockedUserId = _otherUserId;
    if (blockedUserId == null) {
      _showSnackBar('Không tìm thấy người dùng để chặn.');
      return;
    }

    await _runRelationshipAction(
      () => _blockService.createBlock(blockedUserId: blockedUserId),
    );
  }

  Future<bool?> _confirmDangerAction(
    BuildContext context, {
    required String title,
    required String content,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _runRelationshipAction(Future<dynamic> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/matches', (route) => false);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể thực hiện thao tác. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    BondyFeedback.showError(context, message);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildPresenceSubtitle() {
    String text;
    Color color;
    if (_partnerTyping) {
      text = 'Đang nhập...';
      color = BondyColors.primary;
    } else if (!_wsConnected) {
      text = 'Đang kết nối...';
      color = BondyColors.textSecondary;
    } else if (_isPartnerOnline) {
      text = 'Đang hoạt động';
      color = const Color(0xFF22C55E);
    } else {
      text = _formatLastSeen(_partnerLastSeenAt);
      color = BondyColors.textSecondary;
    }
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color),
    );
  }

  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Ngoại tuyến';
    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inSeconds < 60) return 'Hoạt động vừa xong';
    if (diff.inMinutes < 60) return 'Hoạt động ${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return 'Hoạt động ${diff.inHours} giờ trước';
    if (diff.inDays < 7) return 'Hoạt động ${diff.inDays} ngày trước';
    return 'Ngoại tuyến';
  }

  Future<void> _showRelationshipRuleDialog(String message) async {
    String title = 'Không thể gửi lời mời';
    String content = message;
    String emoji = '🔒';

    if (message.contains('Bạn đã có một mối quan hệ đang hoạt động')) {
      title = 'Bạn đã có kết nối';
      content =
          'Tài khoản của bạn hiện đang trong một mối quan hệ hoạt động.\n\nMỗi tài khoản chỉ có thể kết nối với một đối phương duy nhất. Để kết nối với người này, bạn cần kết thúc mối quan hệ hiện tại trước.';
      emoji = '🔗';
    } else if (message.contains(
      'Đối phương đã có một mối quan hệ đang hoạt động',
    )) {
      title = 'Đối phương đã có kết nối';
      content =
          'Người này hiện đang trong một mối quan hệ hoạt động khác.\n\nHọ cần kết thúc mối quan hệ hiện tại của họ trước khi có thể nhận lời mời mới từ bạn.';
      emoji = '👥';
    } else if (message.contains(
      'Bạn đang có một lời mời khác đang chờ phản hồi',
    )) {
      title = 'Đang có lời mời chờ';
      content =
          'Bạn đang có một lời mời kết nối khác đang chờ phản hồi. Bạn cần hủy lời mời đó trước khi có thể gửi lời mời mới.';
      emoji = '⏳';
    } else if (message.contains('Đã có lời mời đang chờ cho kết nối này')) {
      title = 'Lời mời đã gửi';
      content =
          'Một lời mời kết nối đã được gửi cho người này và đang chờ xác nhận.';
      emoji = '💌';
    } else if (message.contains('Hai bạn đã xác nhận mối quan hệ rồi')) {
      title = 'Đã kết nối';
      content = 'Hai bạn hiện đã là một cặp trong ứng dụng!';
      emoji = '💖';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF2D2A26),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
            ),
            child: Text(
              'Đã hiểu',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
