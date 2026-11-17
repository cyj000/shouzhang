import 'package:flutter/material.dart';

/// 一期内置贴纸目录（随包内置，物料不热更）。
///
/// 资源以「程序化矢量绘制」形态内置（自绘、CC0），assetPath 使用 `builtin://` 标识，
/// 避免引入来源不明的二进制素材；如需新增外部素材必须通过 LicenseGuard 导入并留痕。
abstract final class StickerCatalog {
  static const List<BuiltinSticker> builtins = <BuiltinSticker>[
    BuiltinSticker(
      id: 'builtin_coffee',
      label: '咖啡',
      assetPath: 'builtin://coffee',
      attributes: <String>['餐饮', '咖啡'],
      color: Color(0xFF8B5E3C),
      icon: Icons.local_cafe,
    ),
    BuiltinSticker(
      id: 'builtin_food',
      label: '美食',
      assetPath: 'builtin://food',
      attributes: <String>['餐饮'],
      color: Color(0xFFC96F53),
      icon: Icons.restaurant,
    ),
    BuiltinSticker(
      id: 'builtin_bus',
      label: '交通',
      assetPath: 'builtin://bus',
      attributes: <String>['交通'],
      color: Color(0xFF4F7A9B),
      icon: Icons.directions_bus,
    ),
    BuiltinSticker(
      id: 'builtin_book',
      label: '阅读',
      assetPath: 'builtin://book',
      attributes: <String>['学习'],
      color: Color(0xFF6B8E6B),
      icon: Icons.menu_book,
    ),
    BuiltinSticker(
      id: 'builtin_gift',
      label: '礼物',
      assetPath: 'builtin://gift',
      attributes: <String>['人情'],
      color: Color(0xFFB56A8C),
      icon: Icons.card_giftcard,
    ),
    BuiltinSticker(
      id: 'builtin_home',
      label: '居家',
      assetPath: 'builtin://home',
      attributes: <String>['居住'],
      color: Color(0xFF9B8B6B),
      icon: Icons.home_outlined,
    ),
  ];
}

@immutable
class BuiltinSticker {
  const BuiltinSticker({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.attributes,
    required this.color,
    required this.icon,
  });

  final String id;
  final String label;
  final String assetPath;
  final List<String> attributes;
  final Color color;
  final IconData icon;
}
