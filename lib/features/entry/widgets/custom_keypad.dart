import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 自绘金额键盘（DQ-03 / SP-03 对比用）。默认关闭，系统键盘为 DQ-02 默认方案。
class CustomAmountKeypad extends StatelessWidget {
  const CustomAmountKeypad({
    required this.onToken,
    required this.onBackspace,
    required this.onClear,
    super.key,
  });

  final ValueChanged<String> onToken;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const List<List<String>> _rows = <List<String>>[
    <String>['7', '8', '9', '+'],
    <String>['4', '5', '6', '-'],
    <String>['1', '2', '3', '×'],
    <String>['0', '.', '÷', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: Column(
        children: <Widget>[
          for (final row in _rows)
            Row(
              children: <Widget>[
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceXS),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: key == '⌫' || key == '.'
                              ? AppTheme.inkSoft
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: key == '⌫' || key == '.'
                              ? Colors.white
                              : AppTheme.ink,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                        ),
                        onPressed: () {
                          if (key == '⌫') {
                            onBackspace();
                          } else {
                            onToken(key);
                          }
                        },
                        child: Text(key, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
              ],
            ),
          TextButton(onPressed: onClear, child: const Text('清空金额')),
          const SizedBox(height: AppTheme.spaceXS),
        ],
      ),
    );
  }
}
