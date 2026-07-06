import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/swap_request_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'swap_requests_screen.dart';
import 'my_skills_screen.dart';
import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Timer? _globalPollTimer;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatListScreen(),
    SwapRequestsScreen(),
    MySkillsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
      _startGlobalPolling();
    });
  }

  void _loadAllData() {
    if (!mounted) return;
    context.read<SwapRequestProvider>().loadAll();
    context.read<ChatProvider>().loadConversations(silent: true);
    context.read<NotificationProvider>().loadData();
  }

  void _startGlobalPolling() {
    _globalPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollGlobalData(),
    );
  }

  void _pollGlobalData() {
    if (!mounted) return;
    context.read<ChatProvider>().loadConversations(silent: true);
    context.read<NotificationProvider>().refreshData();
    context.read<SwapRequestProvider>().loadAll(silent: true);
  }

  @override
  void dispose() {
    _globalPollTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: c.surface,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textSecondary,
          selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: c.primary,
          ),
          unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            color: c.textSecondary,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Consumer<ChatProvider>(
                builder: (_, provider, _) => _NavBadge(
                  icon: LucideIcons.messageSquare,
                  count: provider.unreadConversationsCount,
                  badgeColor: const Color(0xFFEF4444),
                ),
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Consumer<SwapRequestProvider>(
                builder: (_, provider, _) => _NavBadge(
                  icon: Icons.swap_horiz_rounded,
                  iconSize: 26,
                  count: provider.pendingReceivedCount,
                  badgeColor: const Color(0xFFD97706),
                ),
              ),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.repeat, size: 24),
              label: 'Skills',
            ),
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

class _NavBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final int count;
  final Color badgeColor;

  const _NavBadge({
    required this.icon,
    required this.count,
    required this.badgeColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: iconSize),
        if (count > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
  }
}
