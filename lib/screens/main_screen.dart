import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/swap_request_provider.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'swap_requests_screen.dart';   // ← new screen
import 'my_skills_screen.dart';
import 'setting_screen.dart';
 
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
 
  @override
  State<MainScreen> createState() => _MainScreenState();
}
 
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
 
  final List<Widget> _screens = const [
    HomeScreen(),
    ChatListScreen(),
    SwapRequestsScreen(), // index 2 = Swap Requests tab
    MySkillsScreen(),
    SettingsScreen(),
  ];
 
  @override
  void initState() {
    super.initState();
    // Pre-load swap requests so badge shows immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapRequestProvider>().loadAll();
    });
  }
 
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          items: [
            // 1 – Home
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 24),
              label: 'Home',
            ),
 
            // 2 – Chat
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.messageSquare, size: 24),
              label: 'Chat',
            ),
 
            // 3 – Swap Requests (with badge)
            BottomNavigationBarItem(
              icon: Consumer<SwapRequestProvider>(
                builder: (_, provider, __) {
                  final count = provider.pendingReceivedCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 26),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Requests',
            ),
 
            // 4 – My Skills
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.repeat, size: 24),
              label: 'Skills',
            ),
 
            // 5 – Settings
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}