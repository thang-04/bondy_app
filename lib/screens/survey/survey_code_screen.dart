import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/survey/survey_viewmodel.dart';
import '../../widgets/bondy_button.dart';

class SurveyCodeScreen extends StatefulWidget {
  const SurveyCodeScreen({super.key});

  @override
  State<SurveyCodeScreen> createState() => _SurveyCodeScreenState();
}

class _SurveyCodeScreenState extends State<SurveyCodeScreen> {
  final _codeController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<SurveyViewModel>();
    await vm.loadSurveyByCode(_codeController.text.trim());
    if (!mounted) return;
    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
      return;
    }
    if (vm.questions.isNotEmpty) {
      Navigator.of(context).pushNamed('/survey/question');
    }
  }

  @override
  Widget build(BuildContext context) {
    final survey = context.watch<SurveyViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Nhập mã khảo sát',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: BondyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã khảo sát để tham gia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: BondyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BondyColors.divider),
                  color: Colors.white,
                ),
                child: TextField(
                  key: const Key('survey_code_field'),
                  controller: _codeController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) => setState(() {
                    _isValid = value.trim().isNotEmpty;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Mã khảo sát',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: BondyColors.textHint,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              BondyButton(
                key: const Key('survey_code_submit_button'),
                text: survey.isLoading ? 'Đang tìm...' : 'Tìm khảo sát',
                isLoading: survey.isLoading,
                onPressed: _isValid && !survey.isLoading ? _submit : () {},
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
