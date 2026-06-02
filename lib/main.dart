import 'package:flutter/material.dart';
import 'package:skillswap/screens/chat_list_screen.dart';
import 'package:skillswap/screens/home_screen.dart';
import 'package:skillswap/screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/password_reset_success_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

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
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const NewPasswordScreen(),
        '/reset_password': (context) => const NewPasswordScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/new_password': (context) => const NewPasswordScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(),
        '/password-reset-success': (context) => const PasswordResetSuccessScreen(),
        '/password_reset_success': (context) => const PasswordResetSuccessScreen(),
      },
    );
  }
}
