import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/constants.dart';
import '../../domain/usecases/amount_parser.dart';
import '../ink/ink_editor_page.dart';
import '../sticker/sticker_picker_sheet.dart';
import 'entry_controller.dart';
import 'widgets/custom_keypad.dart' as keypad_widget;

/// 极速记账页（FR-01~06）。冷启动直落此页，金额框优先聚焦（DQ-02）。
class EntryPage extends ConsumerStatefulWidget {
  const EntryPage({super.key});

  @override
  ConsumerState<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<EntryPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  static const List<String> _paymentMethods = <String>[
    '现金',
    '微信',
    '支付宝',
    '银行卡',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(entryControllerProvider.notifier).initialize();
      _amountFocus.requestFocus(); // DQ-02：系统键盘 <300ms 为目标值
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entryControllerProvider);
    final notifier = ref.read(entryControllerProvider.notifier);
    final useCustomKeypad =
        ref.watch(useCustomKeypadProvider).value ?? false;
    final preview = state.previewCents();
    final isExpense = state.type == EntryTypes.expense;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppTheme.spaceL,
            bottom: AppTheme.spaceXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTypeSwitch(isExpense, notifier),
              const SizedBox(height: AppTheme.spaceL),
              _buildAmountField(preview),
              const SizedBox(height: AppTheme.spaceM),
              _buildNoteField(notifier),
              const SizedBox(height: AppTheme.spaceS),
              _buildSuggestions(state, notifier),
              const SizedBox(height: AppTheme.spaceS),
              _buildPaymentMethod(state, notifier),
              if (state.lastSavedEntryId != null) ...<Widget>[
                const SizedBox(height: AppTheme.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => StickerPickerSheet(
                          entryId: state.lastSavedEntryId!,
                        ),
                      ),
                      icon: const Icon(Icons.sticker),
                      label: const Text('贴纸'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InkEditorPage(
                            entryId: state.lastSavedEntryId!,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.brush_outlined),
                      label: const Text('涂鸦'),
                    ),
                  ],
                ),
              ],
              if (state.error != null) ...<Widget>[
                const SizedBox(height: AppTheme.spaceS),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                  ),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceL),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceM,
                ),
                child: FilledButton(
                  onPressed: () async {
                    final ok = await notifier.save();
                    if (ok && mounted) {
                      _amountController.clear();
                      _noteController.clear();
                      _amountFocus.requestFocus(); // 连续记账停留在记账页
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已记下，继续下一笔')),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spaceS),
                    child: Text('记一笔', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              if (useCustomKeypad) ...<Widget>[
                const SizedBox(height: AppTheme.spaceM),
                keypad_widget.CustomAmountKeypad(
                  onToken: (token) {
                    _amountController.text += token;
                    notifier.updateExpression(_amountController.text);
                  },
                  onBackspace: () {
                    if (_amountController.text.isNotEmpty) {
                      _amountController.text = _amountController.text
                          .substring(0, _amountController.text.length - 1);
                      notifier.updateExpression(_amountController.text);
                    }
                  },
                  onClear: () {
                    _amountController.clear();
                    notifier.clearExpression();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSwitch(bool isExpense, EntryController notifier) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXS),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _typeChip('支出', isExpense, AppTheme.expense, () {
              if (!isExpense) notifier.toggleType();
            }),
            _typeChip('收入', !isExpense, AppTheme.income, () {
              if (isExpense) notifier.toggleType();
            }),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceXL,
            vertical: AppTheme.spaceS,
          ),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.inkSoft,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  Widget _buildAmountField(int? preview) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: '¥ ',
              prefixStyle: TextStyle(fontSize: 28),
            ),
            onChanged: (value) =>
                ref.read(entryControllerProvider.notifier).updateExpression(value),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            preview == null ? '支持 25+8、10÷3 等算式' : '= ${formatYuan(preview)} 元',
            style: TextStyle(
              color: preview == null ? AppTheme.inkSoft : AppTheme.accent,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField(EntryController notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: TextField(
        controller: _noteController,
        decoration: const InputDecoration(
          hintText: '写点什么，例如「星巴克 咖啡」',
          prefixIcon: Icon(Icons.edit_outlined),
        ),
        onChanged: (value) => notifier.updateNote(value),
      ),
    );
  }

  Widget _buildSuggestions(EntryFormState state, EntryController notifier) {
    if (state.suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: Wrap(
        spacing: AppTheme.spaceS,
        children: state.suggestions.map((suggestion) {
          final selected =
              state.selectedTagNames.contains(suggestion.tagName);
          return FilterChip(
            label: Text('${suggestion.tagName} · ${suggestion.source}'),
            selected: selected,
            onSelected: (_) => notifier.toggleTag(suggestion),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethod(EntryFormState state, EntryController notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: DropdownButtonFormField<String>(
        value: state.paymentMethod,
        decoration: const InputDecoration(
          labelText: '支付方式',
          prefixIcon: Icon(Icons.payment_outlined),
        ),
        items: _paymentMethods
            .map((method) =>
                DropdownMenuItem<String>(value: method, child: Text(method)))
            .toList(),
        onChanged: (value) {
          if (value != null) notifier.setPaymentMethod(value);
        },
      ),
    );
  }
}
