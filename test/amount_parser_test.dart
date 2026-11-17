import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/domain/entities/constants.dart';
import 'package:paper_ledger/domain/usecases/amount_parser.dart';

void main() {
  const parser = AmountParser();

  test('25+8 = 33.00 元（3300 分）', () {
    final result = parser.parse('25+8');
    expect(result.isSuccess, isTrue);
    expect(result.cents, 3300);
    expect(formatYuan(result.cents), '33.00');
  });

  test('10÷3 = 3.33 元（四舍五入到分）', () {
    final result = parser.parse('10÷3');
    expect(result.isSuccess, isTrue);
    expect(result.cents, 333);
    expect(formatYuan(result.cents), '3.33');
  });

  test('0.1 + 0.2 = 0.30 元（无浮点误差）', () {
    final result = parser.parse('0.1+0.2');
    expect(result.cents, 30);
    expect(formatYuan(result.cents), '0.30');
  });

  test('从左到右计算：10-3+2 = 9.00', () {
    expect(parser.parse('10-3+2').cents, 900);
  });

  test('拒绝负数与括号', () {
    expect(parser.parse('-5').status, AmountParseStatus.negativeNotAllowed);
    expect(
      parser.parse('(1+2)').status,
      AmountParseStatus.parenthesisNotAllowed,
    );
  });

  test('拒绝超上限 100,000,000 分', () {
    expect(
      parser.parse('1000001').status,
      AmountParseStatus.overflow,
    );
    expect(parser.parse('1000000').cents, AmountRules.maxCents);
  });

  test('拒绝除零、多余小数位、连续运算符与非法字符', () {
    expect(parser.parse('1/0').status, AmountParseStatus.divideByZero);
    expect(parser.parse('1.234').status, AmountParseStatus.tooManyDecimals);
    expect(parser.parse('1++2').status, AmountParseStatus.missingOperand);
    expect(parser.parse('abc').status, AmountParseStatus.invalidCharacter);
  });
}
