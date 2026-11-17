import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'app_router.dart';

/// 底部三栏骨架：记账 / 回顾 / 设置。
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedIndex: _indexFor(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RoutePaths.entry);
            case 1:
              context.go(RoutePaths.review);
            case 2:
              context.go(RoutePaths.settings);
          }
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: '记账',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '回顾',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: location == RoutePaths.entry
          ? FloatingActionButton(
              onPressed: () {
                // FR-01 占位：真实实现见 PKG-03。
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('极速记账录入即将就绪')),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  int _indexFor(String location) {
    if (location.startsWith(RoutePaths.review)) return 1;
    if (location.startsWith(RoutePaths.settings)) return 2;
    return 0;
  }
}

/// 供各 feature stub 复用的居中占位（后续包替换为真实页面）。
class FeatureStub extends StatelessWidget {
  const FeatureStub({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: AppTheme.inkSoft),
            const SizedBox(height: AppTheme.spaceM),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
