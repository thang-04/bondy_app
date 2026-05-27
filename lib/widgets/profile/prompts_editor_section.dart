import 'package:flutter/material.dart';
import '../../services/prompts_service.dart';
import '../../theme/app_theme.dart';

class PromptsEditorSection extends StatefulWidget {
  const PromptsEditorSection({super.key});

  @override
  State<PromptsEditorSection> createState() => _PromptsEditorSectionState();
}

class _PromptsEditorSectionState extends State<PromptsEditorSection> {
  final _service = PromptsService();
  List<PromptAnswer> _prompts = [];
  List<PromptCatalogItem> _catalog = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.fetchMyPrompts(),
        _service.fetchCatalog(),
      ]);
      setState(() {
        _prompts = results[0] as List<PromptAnswer>;
        _catalog = results[1] as List<PromptCatalogItem>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPrompt() async {
    if (_prompts.length >= 3) return;
    final selected = await showModalBottomSheet<PromptCatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatalogSheet(
        catalog: _catalog,
        usedPrompts: _prompts.map((p) => p.prompt).toSet(),
      ),
    );
    if (selected == null || !mounted) return;

    final answer = await showDialog<String>(
      context: context,
      builder: (_) => _AnswerDialog(prompt: selected.text),
    );
    if (answer == null || answer.trim().isEmpty) return;

    setState(() {
      _prompts = [
        ..._prompts,
        PromptAnswer(prompt: selected.text, answer: answer.trim()),
      ];
    });
    await _save();
  }

  Future<void> _removePrompt(int index) async {
    setState(() {
      _prompts = List.of(_prompts)..removeAt(index);
    });
    await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await _service.savePrompts(_prompts);
      setState(() => _prompts = saved);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '3 câu nói về bạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Câu trả lời của bạn giúp người khác hiểu bạn hơn',
          style: TextStyle(fontSize: 13, color: BondyColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: SizedBox(
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          ..._prompts.asMap().entries.map(
            (e) => _buildPromptCard(e.key, e.value),
          ),
          if (_prompts.length < 3) _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildPromptCard(int index, PromptAnswer p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BondyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BondyColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.prompt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BondyColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.answer,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BondyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
              color: BondyColors.textSecondary,
            ),
            onPressed: () => _removePrompt(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _addPrompt,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: BondyColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: BondyColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '+ Thêm câu trả lời (${_prompts.length}/3)',
              style: const TextStyle(
                color: BondyColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSheet extends StatelessWidget {
  final List<PromptCatalogItem> catalog;
  final Set<String> usedPrompts;

  const _CatalogSheet({required this.catalog, required this.usedPrompts});

  @override
  Widget build(BuildContext context) {
    final available = catalog
        .where((c) => !usedPrompts.contains(c.text))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: BondyColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: BondyColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Chọn câu hỏi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BondyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: available.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = available[i];
                  return ListTile(
                    title: Text(
                      item.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: BondyColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: BondyColors.primary,
                    ),
                    onTap: () => Navigator.of(ctx).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerDialog extends StatefulWidget {
  final String prompt;

  const _AnswerDialog({required this.prompt});

  @override
  State<_AnswerDialog> createState() => _AnswerDialogState();
}

class _AnswerDialogState extends State<_AnswerDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BondyColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.prompt,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: BondyColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _ctrl,
        maxLength: 200,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Câu trả lời của bạn...',
          hintStyle: TextStyle(color: BondyColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_ctrl.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_ctrl.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: BondyColors.primary),
          child: const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
