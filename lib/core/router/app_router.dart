import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/entry/entry_page.dart';
import '../../features/review/review_page.dart';
import '../../features/settings/settings_page.dart';
import 'app_shell.dart';

/// 声明式路由表（PKG-01）。Cold start 直落 `/entry`（FR-01 / R5）。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.entry,
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.entry,
            name: 'entry',
            builder: (context, state) => const EntryPage(),
          ),
          GoRoute(
            path: RoutePaths.review,
            name: 'review',
            builder: (context, state) => const ReviewPage(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

/// 路由路径常量：避免各 feature 散落字符串（R8 口径统一）。
abstract final class RoutePaths {
  static const String entry = '/entry';
  static const String review = '/review';
  static const String settings = '/settings';
}
