import 'package:flutter/material.dart';
import '../services/store.dart';
import 'feed.dart';
import 'saved.dart';
import 'search.dart';
import 'settings.dart';
import 'tools.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Store.i,
        builder: (_, __) => Scaffold(
          body: IndexedStack(index: _i, children: [
            HomePage(),
            SearchPage(),
            ToolsPage(),
            SavedPage(),
            SettingsPage(),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _i,
            onDestinationSelected: (v) => setState(() => _i = v),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t('home')),
              NavigationDestination(icon: const Icon(Icons.search), label: t('search')),
              NavigationDestination(icon: const Icon(Icons.calculate_outlined), selectedIcon: const Icon(Icons.calculate), label: t('tools')),
              NavigationDestination(icon: const Icon(Icons.bookmark_border), selectedIcon: const Icon(Icons.bookmark), label: t('saved')),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t('settings')),
            ],
          ),
        ),
      );
}
