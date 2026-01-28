import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_screen.dart';

import 'network_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const NetworkScreen(),
    const HelpScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.darkBackground,
          indicatorColor: AppTheme.primaryGreen.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wallet, color: Colors.white54),
              selectedIcon: Icon(Icons.wallet, color: AppTheme.primaryGreen),
              label: 'Wallet',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub, color: Colors.white54),
              selectedIcon: Icon(Icons.hub, color: AppTheme.primaryGreen),
              label: 'Network',
            ),
            NavigationDestination(
              icon: Icon(Icons.help_outline, color: Colors.white54),
              selectedIcon: Icon(Icons.help, color: AppTheme.primaryGreen),
              label: 'Help',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.settings, color: AppTheme.primaryGreen),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
