import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart'; // الشاشة اللي عملناها سوا

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // قائمة الشاشات (ضيفي باقي الشاشات لما تخلصيها)
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Skills Screen')), // استبدليها بملف شاشة المهارات
    const Center(child: Text('Chat Screen')),   // استبدليها بملف شاشة الشات
    const Center(child: Text('Profile Screen')), // استبدليها بملف شاشة البروفايل
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
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
              icon: Icon(LucideIcons.user, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}