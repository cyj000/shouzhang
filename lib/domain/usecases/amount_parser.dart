import '../../domain/entities/constants.dart';

/// 金额算式解析状态（FR-02 / R2）。
enum AmountParseStatus {
  ok,
  empty,
  invalidCharacter,
  negativeNotAllowed,
  parenthesisNotAllowed,
  tooManyDecimals,
  missingOperand,
  divideByZero,
  overflow,
  negativeResult,
}

class AmountParseResult {
  const AmountParseResult._(this.status, this.cents);

  factory AmountParseResult.success(int cents) =>
      AmountParseResult._(AmountParseStatus.ok, cents);

  factory AmountParseResult.failure(AmountParseStatus status) =>
      AmountParseResult._(status, 0);

  final AmountParseStatus status;
  final int cents;
  bool get isSuccess => status == AmountParseStatus.ok;
}

/// FR-02 金额算式：从左到右四则，禁负数/括号，最多 2 位小数，
/// 除不尽四舍五入到分，上限 100,000,000 分。全程 int，禁 double（R2）。
class AmountParser {
  const AmountParser();

  AmountParseResult parse(String raw) {
    var expr = raw
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-');

    if (expr.isEmpty) return AmountParseResult.failure(AmountParseStatus.empty);
    if (expr.startsWith('-')) {
      return AmountParseResult.failure(AmountParseStatus.negativeNotAllowed);
    }
    if (expr.contains('(') || expr.contains(')')) {
      return AmountParseResult.failure(AmountParseStatus.parenthesisNotAllowed);
    }

    var acc = 0;
    String? pendingOp;
    var token = '';

    AmountParseResult? flushToken() {
      if (token.isEmpty) {
        return AmountParseResult.failure(AmountParseStatus.missingOperand);
      }
      final value = _parseCents(token);
      token = '';
      if (value == null) {
        return AmountParseResult.failure(AmountParseStatus.tooManyDecimals);
      }
      if (pendingOp == null) {
        acc = value;
      } else {
        if (pendingOp == '/' && value == 0) {
          return AmountParseResult.failure(AmountParseStatus.divideByZero);
        }
        acc = _apply(acc, value, pendingOp!);
        pendingOp = null;
      }
      if (acc.abs() > AmountRules.maxCents) {
        return AmountParseResult.failure(AmountParseStatus.overflow);
      }
      return null;
    }

    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if (ch == '+' || ch == '-' || ch == '*' || ch == '/') {
        final error = flushToken();
        if (error != null) return error;
        pendingOp = ch;
      } else if ((ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) ||
          ch == '.') {
        token += ch;
      } else {
        return AmountParseResult.failure(AmountParseStatus.invalidCharacter);
      }
    }

    final error = flushToken();
    if (error != null) return error;
    if (acc < 0) return AmountParseResult.failure(AmountParseStatus.negativeResult);
    return AmountParseResult.success(acc);
  }

  /// 单个数解析为分：整数部分 * 100 + 两位小数；超过两位拒绝。
  int? _parseCents(String token) {
    final parts = token.split('.');
    if (parts.length > 2) return null;
    final intValue = int.tryParse(parts[0]);
    if (intValue == null) return null;
    if (parts.length == 1) return intValue * 100;
    final fraction = parts[1];
    if (fraction.length > 2) return null;
    final padded = fraction.padRight(2, '0');
    return intValue * 100 + int.parse(padded);
  }

  /// 从左到右执行；乘除按分四舍五入到分。
  int _apply(int a, int b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        // (a 分 × b 分) / 100 分 = 分，四舍五入。
        return (a * b + 50) ~/ 100;
      case '/':
        // (a 分 / (b/100)) = a*100/b 分，四舍五入。
        return (a * 100 + b ~/ 2) ~/ b;
      default:
        return a;
    }
  }
}

/// 展示格式化：分 → 元（两位小数），全部整数运算（FR-06 / R2）。
String formatYuan(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final yuan = abs ~/ 100;
  final fen = (abs % 100).toString().padLeft(2, '0');
  return '$sign$yuan.$fen';
}
