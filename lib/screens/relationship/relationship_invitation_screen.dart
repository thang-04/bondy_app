import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../healing/healing_stitch_style.dart';
import '../../viewmodels/relationship/relationship_viewmodel.dart';
import '../../widgets/common/bondy_feedback.dart';

class RelationshipInvitationScreen extends StatefulWidget {
  const RelationshipInvitationScreen({super.key});

  @override
  State<RelationshipInvitationScreen> createState() =>
      _RelationshipInvitationScreenState();
}

class _RelationshipInvitationScreenState extends State<RelationshipInvitationScreen> {
  final RelationshipViewModel _viewModel = RelationshipViewModel();
  final TextEditingController _acceptController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  Future<void> _loadInvite() async {
    setState(() => _loading = true);
    try {
      await _viewModel.createInvite();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã mời!')),
    );
  }

  Future<void> _acceptCode() async {
    final code = _acceptController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _viewModel.acceptInvite(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/relationship/confirmed');
    } catch (e) {
      if (!mounted) return;
      BondyFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _acceptController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _viewModel.inviteCode ?? '...';
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: HealingStitchColors.warmBackground,
        elevation: 0,
        leading: HealingIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
        ),
        title: Text('Mời tri kỷ', style: healingText(size: 16, weight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: HealingStitchColors.paleCoral,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Text('💌', style: TextStyle(fontSize: 72))),
            ),
            const SizedBox(height: 32),
            Text(
              'Gắn kết hơn khi có nhau',
              style: healingText(size: 22, weight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Gửi mã cho người yêu hoặc nhập mã họ gửi cho bạn.',
              style: healingText(color: HealingStitchColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HealingStitchColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [healingSoftShadow()],
              ),
              child: Column(
                children: [
                  Text(
                    'MÃ MỜI CỦA BẠN',
                    style: healingText(
                      size: 11,
                      weight: FontWeight.w700,
                      color: HealingStitchColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _loading && code == '...' ? 'Đang tạo...' : code,
                        style: healingText(
                          size: 20,
                          weight: FontWeight.w800,
                          color: HealingStitchColors.coral,
                        ),
                      ),
                      IconButton(
                        onPressed: code == '...'
                            ? null
                            : () => _copyToClipboard(context, code),
                        icon: const Icon(Icons.copy, color: HealingStitchColors.coral),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _acceptController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nhập mã mời',
                filled: true,
                fillColor: HealingStitchColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: HealingStitchColors.warmGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _acceptCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text(
                    'Chấp nhận mã mời',
                    style: healingText(weight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
