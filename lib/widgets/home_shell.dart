import 'package:flutter/material.dart';
import 'package:vidora/core/strings.dart';
import 'package:vidora/core/theme.dart';
import 'package:vidora/screens/bookmarks/bookmarks_screen.dart';
import 'package:vidora/screens/history/history_screen.dart';
import 'package:vidora/screens/home/home_screen.dart';
import 'package:vidora/screens/search/search_screen.dart';
import 'package:vidora/screens/settings/settings_screen.dart';
import 'package:vidora/screens/subscriptions/subscriptions_screen.dart';

/// Root shell with bottom navigation: Home, Search, Subs, History,
/// Bookmarks, Settings. Pages stay alive between tab switches.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    SubscriptionsScreen(),
    HistoryScreen(),
    BookmarksScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 64,
        destinations: [
          NavigationDestination(
            icon: _navIcon('home'),
            selectedIcon: _navIcon('home', selected: true),
            label: context.s.home,
          ),
          NavigationDestination(
            icon: _navIcon('search'),
            selectedIcon: _navIcon('search', selected: true),
            label: context.s.search,
          ),
          NavigationDestination(
            icon: _navIcon('subscriptions'),
            selectedIcon: _navIcon('subscriptions', selected: true),
            label: context.s.subs,
          ),
          NavigationDestination(
            icon: _navIcon('history'),
            selectedIcon: _navIcon('history', selected: true),
            label: context.s.history,
          ),
          NavigationDestination(
            icon: _navIcon('bookmarks'),
            selectedIcon: _navIcon('bookmarks', selected: true),
            label: context.s.saved,
          ),
          NavigationDestination(
            icon: _navIcon('settings'),
            selectedIcon: _navIcon('settings', selected: true),
            label: context.s.settings,
          ),
        ],
      ),
    );
  }

  Widget _navIcon(String name, {bool selected = false}) {
    final color = selected ? V.red : V.textDim;
    return AppIcons.byName(name).icon(size: 22, color: color);
  }
}
