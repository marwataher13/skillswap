import 'package:flutter/material.dart';
import 'package:skillswap/screens/main_screen.dart';
import 'theme/app_theme.dart'; // استيراد الثيم الجديد
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      
      // ─── الربط بالثيم الاحترافي ──────────────────────────────────────
      // هنا بنستخدم الـ lightTheme اللي عرفناه في ملف app_theme.dart
      theme: AppTheme.lightTheme, 
      
      // ─── إعدادات المسارات (Navigation) ──────────────────────────────
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}