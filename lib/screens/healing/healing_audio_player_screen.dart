import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/bondy_error_mapper.dart';
import '../../models/healing/healing_models.dart';
import '../../services/healing/healing_service.dart';
import '../../widgets/common/bondy_feedback.dart';
import '../../widgets/navigation/bondy_bottom_nav_bar.dart';
import 'healing_navigation.dart';
import 'healing_stitch_style.dart';

class HealingAudioPlayerScreen extends StatefulWidget {
  final bool planMode;
  final String? audioId;
  final HealingDataSource? service;

  const HealingAudioPlayerScreen({
    super.key,
    this.planMode = false,
    this.audioId,
    this.service,
  });

  @override
  State<HealingAudioPlayerScreen> createState() =>
      _HealingAudioPlayerScreenState();
}

class _HealingAudioPlayerScreenState extends State<HealingAudioPlayerScreen> {
  late final HealingDataSource _service;
  final AudioPlayer _player = AudioPlayer();

  HealingAudio? _audio;
  bool _isLoading = true;
  bool _isAudioReady = false;
  bool _isFavorite = false;
  String? _errorMessage;
  String? _playbackErrorMessage;
  Timer? _sleepTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  static const _favoritesKey = 'healing_audio_favorites';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? HealingService();
    _positionSub = _player.positionStream.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _durationSub = _player.durationStream.listen((value) {
      if (!mounted || value == null) return;
      setState(() => _duration = value);
    });
    _stateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String? _resolveAudioId() {
    if (widget.audioId != null && widget.audioId!.isNotEmpty) {
      return widget.audioId;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) return args;
    if (args is Map) {
      final audioId = args['audioId'] ?? args['contentId'] ?? args['id'];
      if (audioId is String && audioId.isNotEmpty) return audioId;
    }
    return null;
  }

  bool _isPlanMode() {
    if (widget.planMode) return true;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map && args['planMode'] == true;
  }

  Future<void> _bootstrap() async {
    final id = _resolveAudioId();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _playbackErrorMessage = null;
      _isAudioReady = false;
    });
    if (id == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Thiếu mã audio. Vui lòng mở lại từ màn hình lộ trình hoặc thư viện.';
      });
      return;
    }
    try {
      final audio = await _service.fetchAudio(id);
      if (!mounted) return;
      setState(() {
        _audio = audio;
        _duration = Duration(seconds: audio.durationSeconds);
      });
      await _loadFavoriteState(id);
      if (audio.audioUrl.isEmpty) {
        setState(() {
          _playbackErrorMessage =
              'Audio chưa có file phát. Bạn vẫn có thể hoàn thành session để ghi nhận tiến trình.';
        });
        return;
      }
      try {
        await _player.setUrl(audio.audioUrl);
        if (!mounted) return;
        setState(() {
          _duration =
              _player.duration ?? Duration(seconds: audio.durationSeconds);
          _isAudioReady = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _playbackErrorMessage =
              'Audio chưa phát được file hiện tại. Bạn vẫn có thể hoàn thành session để ghi nhận tiến trình.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = BondyErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoriteState(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (!mounted) return;
    setState(() => _isFavorite = favorites.contains(id));
  }

  Future<void> _toggleFavorite() async {
    final id = _audio?.id ?? _resolveAudioId();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (_isFavorite) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await prefs.setStringList(_favoritesKey, favorites);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    BondyFeedback.showSuccess(
      context,
      _isFavorite ? 'Đã thêm vào yêu thích.' : 'Đã bỏ yêu thích.',
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekRelative(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final max = _duration.inMilliseconds > 0
        ? _duration
        : const Duration(minutes: 15);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target);
    await _player.seek(clamped);
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HealingStitchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hẹn giờ ngủ',
                  style: healingText(size: 18, weight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final minutes in [15, 30, 45]) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '$minutes phút',
                      style: healingText(weight: FontWeight.w700),
                    ),
                    trailing: const Icon(Icons.timer_outlined),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _startSleepTimer(Duration(minutes: minutes));
                    },
                  ),
                ],
                if (_sleepTimer != null)
                  TextButton(
                    onPressed: () {
                      _sleepTimer?.cancel();
                      _sleepTimer = null;
                      Navigator.pop(sheetContext);
                      BondyFeedback.showSuccess(context, 'Đã hủy hẹn giờ.');
                    },
                    child: const Text('Hủy hẹn giờ'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () async {
      await _player.pause();
      if (!mounted) return;
      BondyFeedback.showSuccess(context, 'Đã tạm dừng theo hẹn giờ ngủ.');
    });
    BondyFeedback.showSuccess(
      context,
      'Sẽ tạm dừng sau ${duration.inMinutes} phút.',
    );
  }

  void _showMenu() {
    final transcript = _audio?.transcript;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HealingStitchColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuỳ chọn',
                  style: healingText(size: 18, weight: FontWeight.w800),
                ),
                if (transcript != null && transcript.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    transcript,
                    style: healingText(
                      size: 13,
                      color: HealingStitchColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Chưa có transcript cho session này.',
                      style: healingText(color: HealingStitchColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  Widget _buildCover() {
    final url = _audio?.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(HealingStitchAssets.meditation, fit: BoxFit.cover),
      );
    }
    return Image.asset(HealingStitchAssets.meditation, fit: BoxFit.cover);
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final title = _audio?.title ?? 'Nhạc nền thư giãn';
    final subtitle = _audio?.narratorName ?? 'Bondy Wellness';

    return Scaffold(
      backgroundColor: HealingStitchColors.creamBackground,
      bottomNavigationBar: BondyBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          final route = switch (index) {
            0 => '/home',
            1 => healingHomeRoute,
            2 => '/home/matches',
            3 => '/home/profile',
            _ => '/home',
          };
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        },
        onMatchTap: () => Navigator.of(context).pushNamed('/discover'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: HealingStitchColors.pink,
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: healingText(color: HealingStitchColors.textMuted),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                children: [
                  HealingTopBar(
                    title: _isPlaying ? 'Đang nghe' : 'Tạm dừng',
                    trailingIcon: Icons.more_vert,
                    onBack: () => Navigator.of(context).maybePop(),
                    onTrailing: _showMenu,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 320,
                      child: _buildCover(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: healingText(size: 28, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: healingText(
                      size: 13,
                      color: HealingStitchColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _progress,
                      backgroundColor: const Color(0xFFE1DBDE),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFB70047),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: healingText(
                          size: 12,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: healingText(
                          size: 12,
                          color: HealingStitchColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _DisabledControl(icon: Icons.shuffle, label: 'Shuffle'),
                      _ControlCircle(
                        icon: Icons.replay_10,
                        size: 52,
                        iconSize: 28,
                        filled: false,
                        onTap: () => _seekRelative(-10),
                      ),
                      _ControlCircle(
                        icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 78,
                        iconSize: 42,
                        filled: true,
                        onTap: _togglePlayback,
                      ),
                      _ControlCircle(
                        icon: Icons.forward_10,
                        size: 52,
                        iconSize: 28,
                        filled: false,
                        onTap: () => _seekRelative(10),
                      ),
                      _DisabledControl(icon: Icons.repeat, label: 'Repeat'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FooterQuickAction(
                        icon: Icons.timer_outlined,
                        label: 'Hẹn giờ ngủ',
                        onTap: _showSleepTimerSheet,
                      ),
                      _FooterQuickAction(
                        icon: _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Yêu thích',
                        onTap: _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: HealingGradientButton(
            label: 'Hoàn thành session',
            icon: Icons.check_circle,
            onTap: () {
              if (_isPlanMode()) {
                Navigator.of(context).maybePop(true);
                return;
              }
              Navigator.of(context).pushNamed(healingReflectionCompleteRoute);
            },
          ),
        ),
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool filled;
  final VoidCallback onTap;

  const _ControlCircle({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled ? HealingStitchColors.brandGradient : null,
            color: filled ? null : HealingStitchColors.surface,
            boxShadow: [healingSoftShadow(filled ? 0.2 : 0.06)],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: filled ? Colors.white : HealingStitchColors.textMain,
          ),
        ),
      ),
    );
  }
}

class _DisabledControl extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DisabledControl({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label sẽ có trong bản cập nhật tới',
      child: Opacity(
        opacity: 0.38,
        child: Icon(icon, color: HealingStitchColors.textSoft),
      ),
    );
  }
}

class _FooterQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HealingStitchColors.surface,
              shape: BoxShape.circle,
              boxShadow: [healingSoftShadow(0.05)],
            ),
            child: Icon(icon, color: HealingStitchColors.textSoft),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: healingText(size: 12, color: HealingStitchColors.textSoft),
          ),
        ],
      ),
    );
  }
}
