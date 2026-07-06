import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:skillswap/providers/review_provider.dart';
import 'package:skillswap/providers/notification_provider.dart';
import 'package:skillswap/providers/chat_provider.dart';
import 'package:skillswap/providers/swap_request_provider.dart';
import 'package:skillswap/providers/theme_provider.dart';
import 'package:skillswap/screens/profile_screen.dart';
import 'package:skillswap/screens/profile_view_screen.dart';
import 'package:skillswap/screens/skill_details_screen.dart';
import 'package:skillswap/screens/notifications_screen.dart';
import 'package:skillswap/widgets/change_password_sheet.dart';
import 'package:skillswap/screens/chat_list_screen.dart';
import 'package:skillswap/screens/home_screen.dart';
import 'package:skillswap/screens/main_screen.dart';
import 'package:skillswap/screens/setting_screen.dart';
import 'package:skillswap/screens/categories_dashboard_screen.dart';
import 'package:skillswap/screens/advanced_search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/password_reset_success_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SwapRequestProvider()),
      ],
      child: const SkillSwapApp(),
    ),
  );
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'SkillSwap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode:
            themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/chat': (context) => const ChatListScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const NewPasswordScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/verify-otp': (context) => const VerifyOtpScreen(),
        '/password-reset-success': (context) =>
            const PasswordResetSuccessScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileViewScreen(),
        '/edit-profile': (context) => const ProfileScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/skill-details': (context) => const SkillDetailsScreen(),
        '/categories': (context) => const CategoriesDashboardScreen(),
        '/search': (context) => const AdvancedSearchScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    ),
    );
  }
}
