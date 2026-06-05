import 'package:flutter/material.dart';

import '../../features/songs/presentation/songs_page.dart';
import '../../features/setlists/presentation/setlists_page.dart';
import '../../features/settings/presentation/settings_page.dart';

import 'navigation_item.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int selectedIndex = 0;

  late final List<NavigationItem> items = [
    NavigationItem(
      label: 'Songs',
      icon: Icons.library_music,
      page: const SongsPage(),
    ),
    NavigationItem(
      label: 'Setlists',
      icon: Icons.queue_music,
      page: const SetlistsPage(),
    ),
    NavigationItem(
      label: 'Settings',
      icon: Icons.settings,
      page: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: items[selectedIndex].page,
          ),
        ],
      ),
    );
  }
}