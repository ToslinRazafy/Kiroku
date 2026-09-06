import 'package:flutter/material.dart';

import '../../widgets/otaku_bottom_nav.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  double _opacity = 1;

  static const _screens = [
    HomeScreen(),
    LibraryScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    OtakuNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    OtakuNavItem(
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories_rounded,
      label: 'Bibliothèque',
    ),
    OtakuNavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Stats',
    ),
    OtakuNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Réglages',
    ),
  ];

  // Petit fondu (façon page qui tourne) plutôt qu'un cut brutal entre
  // onglets, tout en gardant l'IndexedStack pour préserver le scroll
  // et l'état de chaque écran.
  void _onSelect(int i) {
    if (i == _index) return;
    setState(() => _opacity = 0);
    Future.delayed(const Duration(milliseconds: 110), () {
      if (!mounted) return;
      setState(() {
        _index = i;
        _opacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: OtakuBottomNav(
        selectedIndex: _index,
        onSelected: _onSelect,
        items: _items,
      ),
    );
  }
}
