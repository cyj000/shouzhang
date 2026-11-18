import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 一期内置贴纸目录（视觉专项 VPKG-03：24 款生活物件，全部自绘矢量 / CC0）。
///
/// 资源以「程序化矢量绘制」形态内置（自绘即 CC0），assetPath 使用 `builtin://` 标识，
/// 避免引入来源不明的二进制素材；导入外部素材必须走 LicenseGuard 并在
/// docs/license_audit.md 留痕。
///
/// 软删历史实例走 `assetPathSnapshot` 冗余快照（见 sticker_application），
/// 因此本目录条目增减不影响 REV-05 历史渲染。
abstract final class StickerCatalog {
  static const List<BuiltinSticker> builtins = <BuiltinSticker>[
    // —— 餐饮 ——
    BuiltinSticker(
      id: 'builtin_coffee',
      label: '咖啡',
      assetPath: 'builtin://coffee',
      attributes: <String>['餐饮', '咖啡'],
      color: AppColors.stickerCoffee,
      icon: Icons.local_cafe,
    ),
    BuiltinSticker(
      id: 'builtin_food',
      label: '美食',
      assetPath: 'builtin://food',
      attributes: <String>['餐饮'],
      color: AppColors.stickerCoral,
      icon: Icons.restaurant,
    ),
    BuiltinSticker(
      id: 'builtin_cake',
      label: '甜点',
      assetPath: 'builtin://cake',
      attributes: <String>['餐饮', '甜点'],
      color: AppColors.tapePink,
      icon: Icons.cake_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_tea',
      label: '茶饮',
      assetPath: 'builtin://tea',
      attributes: <String>['餐饮', '饮品'],
      color: AppColors.accentMint,
      icon: Icons.emoji_food_beverage_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_fruit',
      label: '水果',
      assetPath: 'builtin://fruit',
      attributes: <String>['餐饮', '健康'],
      color: AppColors.stickerYellow,
      icon: Icons.apple,
    ),
    BuiltinSticker(
      id: 'builtin_bread',
      label: '面包',
      assetPath: 'builtin://bread',
      attributes: <String>['餐饮', '早餐'],
      color: AppColors.stickerCoffee,
      icon: Icons.bakery_dining_outlined,
    ),

    // —— 出行 ——
    BuiltinSticker(
      id: 'builtin_bus',
      label: '公交',
      assetPath: 'builtin://bus',
      attributes: <String>['交通'],
      color: AppColors.stickerBlue,
      icon: Icons.directions_bus,
    ),
    BuiltinSticker(
      id: 'builtin_train',
      label: '火车',
      assetPath: 'builtin://train',
      attributes: <String>['交通', '长途'],
      color: AppColors.stickerBlue,
      icon: Icons.train_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_plane',
      label: '旅行',
      assetPath: 'builtin://plane',
      attributes: <String>['交通', '旅行'],
      color: AppColors.stickerBlue,
      icon: Icons.flight_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_bike',
      label: '骑行',
      assetPath: 'builtin://bike',
      attributes: <String>['交通', '运动'],
      color: AppColors.accentMint,
      icon: Icons.directions_bike_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_taxi',
      label: '打车',
      assetPath: 'builtin://taxi',
      attributes: <String>['交通'],
      color: AppColors.stickerYellow,
      icon: Icons.local_taxi_outlined,
    ),

    // —— 居家 / 生活 ——
    BuiltinSticker(
      id: 'builtin_home',
      label: '居家',
      assetPath: 'builtin://home',
      attributes: <String>['居住'],
      color: AppColors.stickerCoffee,
      icon: Icons.home_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_pet',
      label: '宠物',
      assetPath: 'builtin://pet',
      attributes: <String>['生活', '宠物'],
      color: AppColors.tapePink,
      icon: Icons.pets_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_plant',
      label: '绿植',
      assetPath: 'builtin://plant',
      attributes: <String>['生活', '居家'],
      color: AppColors.accentMint,
      icon: Icons.eco_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_clean',
      label: '家务',
      assetPath: 'builtin://clean',
      attributes: <String>['生活', '家务'],
      color: AppColors.stickerBlue,
      icon: Icons.cleaning_services_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_light',
      label: '水电',
      assetPath: 'builtin://light',
      attributes: <String>['居住', '缴费'],
      color: AppColors.stickerYellow,
      icon: Icons.lightbulb_outline,
    ),

    // —— 学习 / 工作 ——
    BuiltinSticker(
      id: 'builtin_book',
      label: '阅读',
      assetPath: 'builtin://book',
      attributes: <String>['学习'],
      color: AppColors.accentMint,
      icon: Icons.menu_book,
    ),
    BuiltinSticker(
      id: 'builtin_school',
      label: '学费',
      assetPath: 'builtin://school',
      attributes: <String>['学习', '教育'],
      color: AppColors.stickerBlue,
      icon: Icons.school_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_work',
      label: '办公',
      assetPath: 'builtin://work',
      attributes: <String>['工作'],
      color: AppColors.stickerCoffee,
      icon: Icons.work_outline,
    ),

    // —— 人情 / 娱乐 / 健康 ——
    BuiltinSticker(
      id: 'builtin_gift',
      label: '礼物',
      assetPath: 'builtin://gift',
      attributes: <String>['人情'],
      color: AppColors.tapePink,
      icon: Icons.card_giftcard,
    ),
    BuiltinSticker(
      id: 'builtin_movie',
      label: '观影',
      assetPath: 'builtin://movie',
      attributes: <String>['娱乐'],
      color: AppColors.stickerCoral,
      icon: Icons.movie_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_music',
      label: '音乐',
      assetPath: 'builtin://music',
      attributes: <String>['娱乐'],
      color: AppColors.stickerBlue,
      icon: Icons.music_note_outlined,
    ),
    BuiltinSticker(
      id: 'builtin_health',
      label: '健康',
      assetPath: 'builtin://health',
      attributes: <String>['医疗', '健康'],
      color: AppColors.accentMint,
      icon: Icons.favorite_outline,
    ),
    BuiltinSticker(
      id: 'builtin_sport',
      label: '运动',
      assetPath: 'builtin://sport',
      attributes: <String>['运动', '健康'],
      color: AppColors.stickerCoral,
      icon: Icons.sports_soccer_outlined,
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
