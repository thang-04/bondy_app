import 'package:flutter/material.dart';
import '../../services/safety_checkin_service.dart';
import '../../theme/app_theme.dart';

class PreDateCheckinScreen extends StatefulWidget {
  const PreDateCheckinScreen({super.key});

  @override
  State<PreDateCheckinScreen> createState() => _PreDateCheckinScreenState();
}

class _PreDateCheckinScreenState extends State<PreDateCheckinScreen> {
  final _locationCtrl = TextEditingController();
  DateTime _expectedReturn = DateTime.now().add(const Duration(hours: 3));
  bool _saving = false;
  String? _error;

  final _service = SafetyCheckinService();

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReturnTime() async {
    final picked = await showDateTimePicker(context, _expectedReturn);
    if (picked != null) setState(() => _expectedReturn = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.createCheckin(
        location: _locationCtrl.text.trim(),
        expectedReturnAt: _expectedReturn,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã tạo check-in an toàn')));
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BondyColors.background,
      appBar: AppBar(
        backgroundColor: BondyColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BondyColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Check-in an toàn trước hẹn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BondyColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BondyColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: BondyColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'App sẽ nhắc bạn xác nhận an toàn sau buổi hẹn. Nếu không phản hồi, chúng tôi sẽ ghi nhận để bảo vệ bạn.',
                        style: TextStyle(
                          fontSize: 13,
                          color: BondyColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Địa điểm hẹn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Cà phê The Coffee House, Q.1',
                  hintStyle: TextStyle(color: BondyColors.textSecondary),
                  filled: true,
                  fillColor: BondyColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: BondyColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: BondyColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dự kiến về lúc',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickReturnTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: BondyColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BondyColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: BondyColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDateTime(_expectedReturn),
                        style: const TextStyle(
                          fontSize: 15,
                          color: BondyColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: BondyColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: BondyColors.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BondyColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Bật check-in an toàn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

Future<DateTime?> showDateTimePicker(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 7)),
    builder: (ctx, child) => Theme(
      data: Theme.of(
        ctx,
      ).copyWith(colorScheme: ColorScheme.light(primary: BondyColors.primary)),
      child: child!,
    ),
  );
  if (date == null) return null;

  if (!context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
