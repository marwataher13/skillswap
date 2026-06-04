import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skillswap/screens/chat_list_screen.dart';
import 'package:skillswap/screens/my_skills_screen.dart';
import 'package:skillswap/screens/setting_screen.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MySkillsScreen(),
    const ChatListScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 24),
              activeIcon: Icon(LucideIcons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.repeat, size: 24),
              label: 'Skills',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.messageSquare, size: 24),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}