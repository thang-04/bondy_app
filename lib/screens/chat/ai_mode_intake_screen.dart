import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai_mode_catalog.dart';
import '../../core/ai_mode_intake.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class AiModeIntakeScreen extends StatefulWidget {
  const AiModeIntakeScreen({super.key});

  @override
  State<AiModeIntakeScreen> createState() => _AiModeIntakeScreenState();
}

class _AiModeIntakeScreenState extends State<AiModeIntakeScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _choiceValues = {};
  final Map<String, String> _errors = {};

  AiChatMode _mode = AiChatMode.defaultMode;
  AiModeIntakeConfig _config = AiModeIntakeConfig.defaultMode;
  bool _didInit = false;

  AiModeDescriptor get _descriptor => AiModeCatalog.byMode(_mode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? conversationId;
    if (args is Map<String, dynamic>) {
      _mode = AiChatMode.fromJson(args['mode']);
      conversationId = args['conversationId']?.toString();
    }
    _config = AiModeIntakeConfig.byMode(_mode);

    for (final field in _config.fields) {
      if (field.type == AiIntakeFieldType.choice) {
        if (field.options.isNotEmpty) {
          _choiceValues[field.key] = field.options.first.value;
        }
      } else {
        _controllers[field.key] = TextEditingController();
      }
    }

    // Mở lại một cuộc trò chuyện cũ từ lịch sử: bỏ qua bước intake và đi thẳng
    // tới màn chat/đọc bài để nạp lại hội thoại theo conversationId, thay vì
    // bắt người dùng nhập lại các câu hỏi như bắt đầu mới.
    if (conversationId != null && conversationId.isNotEmpty) {
      final destination =
          AiModeIntakeDraft(mode: _mode, values: const {}).destinationRoute;
      final resumeId = conversationId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          destination,
          arguments: {
            'mode': _mode.apiValue,
            'conversationId': resumeId,
          },
        );
      });
      return;
    }

    if (!AiModeIntakeConfig.requiresIntake(_mode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/bondy-ai',
          arguments: {'mode': _mode.apiValue},
        );
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: BondyColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _config.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: BondyColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              ..._config.fields.map(_buildField),
              const SizedBox(height: 8),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BondyRadius.md),
        border: Border.all(color: BondyColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(_descriptor.avatarAsset, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config.title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BondyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _config.subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: BondyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(AiIntakeField field) {
    final error = _errors[field.key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BondyColors.textPrimary,
                  ),
                ),
              ),
              if (field.required)
                Text(
                  'Bat buoc',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: BondyColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (field.type == AiIntakeFieldType.choice)
            _buildChoiceField(field)
          else
            _buildTextField(field),
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceField(AiIntakeField field) {
    final selected = _choiceValues[field.key];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: field.options
          .map(
            (option) => ChoiceChip(
              key: Key('ai_intake_choice_${field.key}_${option.value}'),
              selected: selected == option.value,
              label: Text(option.label),
              selectedColor: BondyColors.primary.withValues(alpha: 0.14),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected == option.value
                    ? BondyColors.primary
                    : BondyColors.divider,
              ),
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected == option.value
                    ? BondyColors.primary
                    : BondyColors.textPrimary,
              ),
              onSelected: (_) {
                setState(() {
                  _choiceValues[field.key] = option.value;
                  _errors.remove(field.key);
                });
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField(AiIntakeField field) {
    final multiline = field.type == AiIntakeFieldType.multiline;
    return TextField(
      key: Key('ai_intake_field_${field.key}'),
      controller: _controllers[field.key],
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 5 : 1,
      textInputAction: multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        hintText: field.hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 13,
          color: BondyColors.textHint,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: const BorderSide(color: BondyColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BondyRadius.md),
          borderSide: const BorderSide(color: BondyColors.primary),
        ),
      ),
      style: GoogleFonts.manrope(fontSize: 14, color: BondyColors.textPrimary),
      onChanged: (_) {
        if (_errors.containsKey(field.key)) {
          setState(() => _errors.remove(field.key));
        }
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('ai_intake_submit'),
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: BondyColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BondyRadius.md),
          ),
        ),
        child: Text(
          _config.submitLabel,
          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _submit() {
    final values = <String, String>{..._choiceValues};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text.trim();
    }

    final nextErrors = <String, String>{};
    for (final field in _config.fields) {
      if (field.required && (values[field.key]?.trim().isEmpty ?? true)) {
        nextErrors[field.key] = 'Vui long nhap thong tin nay';
      }
    }

    if (nextErrors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(nextErrors);
      });
      return;
    }

    final draft = AiModeIntakeDraft(mode: _mode, values: values);
    Navigator.of(context).pushReplacementNamed(
      draft.destinationRoute,
      arguments: {
        'mode': _mode.apiValue,
        'initialMessage': draft.buildInitialMessage(),
        'displayMessage': draft.displayMessage,
        'intakeSummary': draft.summaryLines,
        'spread': draft.values['spread'],
        'question': draft.values['question'],
      },
    );
  }
}
