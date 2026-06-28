import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../healing/healing_stitch_style.dart';
import '../../services/payment_service.dart';

/// Creates a SePay Payment Gateway order for a subscription [tier], opens SePay's
/// hosted checkout in the browser, and polls the backend until the IPN settles
/// the order. Pops `true` when payment is confirmed.
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
  bool _autoOpened = false;

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
      _autoOpened = false;
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
      // Open the SePay checkout page automatically once.
      if (!_autoOpened) {
        _autoOpened = true;
        _openCheckout();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  Future<void> _openCheckout() async {
    final order = _order;
    if (order == null || order.checkoutUrl.isEmpty) return;
    final uri = Uri.tryParse(order.checkoutUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được trang thanh toán')),
      );
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
            Text(
              'Thanh toán thành công!',
              style: healingText(size: 20, weight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
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
            child: Text(
              'Tuyệt vời',
              style: healingText(
                  weight: FontWeight.w700, color: HealingStitchColors.coral),
            ),
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
          Text(
            _error ?? 'Đã xảy ra lỗi',
            style: healingText(color: HealingStitchColors.textMuted),
            textAlign: TextAlign.center,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(child: Text(order.planName ?? 'Gói ${order.tier}',
              style: healingText(size: 24, weight: FontWeight.w800))),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _formatVnd(order.amount) +
                  (order.period != null ? ' / ${order.period}' : ''),
              style: healingText(
                  size: 18, weight: FontWeight.w700, color: HealingStitchColors.coral),
            ),
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HealingStitchColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HealingStitchColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_outline,
                    color: HealingStitchColors.coral, size: 36),
                const SizedBox(height: 12),
                Text(
                  expired
                      ? 'Đơn hàng đã hết hạn'
                      : 'Thanh toán an toàn qua cổng SePay',
                  style: healingText(size: 16, weight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  expired
                      ? 'Tạo đơn mới để tiếp tục thanh toán.'
                      : 'Nhấn nút bên dưới để mở trang thanh toán (quét VietQR / NAPAS). '
                          'Sau khi chuyển khoản thành công, gói sẽ tự kích hoạt — bạn quay lại app là xong.',
                  style: healingText(size: 13, color: HealingStitchColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                if (!expired) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: HealingStitchColors.textMuted),
                      const SizedBox(width: 6),
                      Text('Hết hạn sau ${_formatRemaining(_remaining)}',
                          style: healingText(
                              size: 13, color: HealingStitchColors.textMuted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (expired)
            ElevatedButton(
              onPressed: _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: HealingStitchColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text('Tạo đơn mới', style: healingText(color: Colors.white)),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: _openCheckout,
              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
              label: Text('Mở trang thanh toán',
                  style: healingText(weight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: HealingStitchColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text('Đang chờ xác nhận thanh toán...',
                    style: healingText(color: HealingStitchColors.textMuted)),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
