import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../healing/healing_stitch_style.dart';
import '../../services/payment_service.dart';

/// Shows a SePay VietQR code for a subscription [tier] inline (works on web +
/// mobile) and polls the backend until the transaction webhook settles the
/// order. Pops `true` when payment is confirmed.
class PaymentCheckoutScreen extends StatefulWidget {
  final String tier;
  final PaymentService? service;

  const PaymentCheckoutScreen({super.key, required this.tier, this.service});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  late final PaymentService _service = widget.service ?? PaymentService();

  PaymentOrder? _order;
  String? _error;
  bool _creating = true;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _createOrder() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final order = await _service.createSubscriptionOrder(widget.tier);
      if (!mounted) return;
      setState(() {
        _order = order;
        _creating = false;
      });
      _startCountdown();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    void tick() {
      final order = _order;
      if (order == null) return;
      final left = order.expiresAt.difference(DateTime.now());
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final order = _order;
    if (order == null) return;
    try {
      final updated = await _service.getOrder(order.id);
      if (!mounted) return;
      setState(() => _order = updated);

      if (updated.isPaid) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        _onPaid();
      } else if (updated.isExpired) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      }
    } catch (_) {
      // Transient polling error — keep trying on the next tick.
    }
  }

  void _onPaid() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: HealingStitchColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: HealingStitchColors.coral, size: 64),
            const SizedBox(height: 16),
            Text('Thanh toán thành công!',
                style: healingText(size: 20, weight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Gói ${_order?.planName ?? _order?.tier ?? ''} của bạn đã được kích hoạt.',
              style: healingText(color: HealingStitchColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tuyệt vời',
                style: healingText(
                    weight: FontWeight.w700, color: HealingStitchColors.coral)),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealingStitchColors.warmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HealingStitchColors.textMain,
        title: Text('Thanh toán', style: healingText(size: 18, weight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _creating
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: HealingStitchColors.orange, size: 56),
          const SizedBox(height: 16),
          Text(_error ?? 'Đã xảy ra lỗi',
              style: healingText(color: HealingStitchColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: HealingStitchColors.coral,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
            ),
            child: Text('Thử lại', style: healingText(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final expired = order.isExpired || _remaining == Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(order.planName ?? 'Gói ${order.tier}',
              style: healingText(size: 22, weight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            _formatVnd(order.amount) +
                (order.period != null ? ' / ${order.period}' : ''),
            style: healingText(
                size: 16, weight: FontWeight.w700, color: HealingStitchColors.coral),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // QR card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HealingStitchColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HealingStitchColors.border),
            ),
            child: Column(
              children: [
                if (expired)
                  _expiredOverlay()
                else ...[
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      order.qrUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2,
                                size: 48, color: HealingStitchColors.textMuted),
                            const SizedBox(height: 8),
                            Text('Không tải được mã QR',
                                style: healingText(
                                    color: HealingStitchColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: HealingStitchColors.textMuted),
                      const SizedBox(width: 6),
                      Text('Mã hết hạn sau ${_formatRemaining(_remaining)}',
                          style: healingText(
                              size: 13, color: HealingStitchColors.textMuted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transfer details (for manual transfer / verification)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HealingStitchColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HealingStitchColors.border),
            ),
            child: Column(
              children: [
                _detailRow('Ngân hàng', order.bankCode, copyable: false),
                _detailRow('Số tài khoản', order.accountNumber),
                if (order.accountHolder != null &&
                    order.accountHolder!.isNotEmpty)
                  _detailRow('Chủ tài khoản', order.accountHolder!,
                      copyable: false),
                _detailRow('Số tiền', _formatVnd(order.amount),
                    copyValue: order.amount.toString()),
                _detailRow('Nội dung CK', order.transferContent, highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HealingStitchColors.paleCoral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Quét mã bằng app ngân hàng và chuyển khoản đúng số tiền & nội dung. '
              'Gói sẽ tự động kích hoạt ngay sau khi nhận được tiền — bạn không cần thao tác gì thêm.',
              style: healingText(size: 13, color: HealingStitchColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          if (expired)
            ElevatedButton(
              onPressed: _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: HealingStitchColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text('Tạo mã mới', style: healingText(color: Colors.white)),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text('Đang chờ thanh toán...',
                    style: healingText(color: HealingStitchColors.textMuted)),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _expiredOverlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.timer_off_outlined,
              size: 56, color: HealingStitchColors.textMuted),
          const SizedBox(height: 12),
          Text('Mã QR đã hết hạn',
              style: healingText(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tạo mã mới để tiếp tục thanh toán.',
              style: healingText(size: 13, color: HealingStitchColors.textMuted)),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool copyable = true,
    bool highlight = false,
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: healingText(
                    size: 13, color: HealingStitchColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: healingText(
                size: 14,
                weight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? HealingStitchColors.coral
                    : HealingStitchColors.textMain,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () => _copy(copyValue ?? value, label),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child:
                    Icon(Icons.copy, size: 18, color: HealingStitchColors.coral),
              ),
            ),
        ],
      ),
    );
  }
}
