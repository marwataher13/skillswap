import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;
 
   @override
   void initState() {
     super.initState();
     _controller = AnimationController(
       duration: const Duration(milliseconds: 1500),
       vsync: this,
     );
     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
     _controller.forward();
 
     _timer = Timer(const Duration(seconds: 3), () async {
       if (mounted) {
         final hasActiveSession = await AuthService.hasToken();
         if (mounted) {
           if (hasActiveSession) {
             Navigator.pushReplacementNamed(context, '/main');
           } else {
             Navigator.pushReplacementNamed(context, '/login');
           }
         }
       }
     });
   }
 
   @override
   void dispose() {
     _timer?.cancel();
     _controller.dispose();
     super.dispose();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.refreshCw,
                  size: 60,
                  color: AppColors.gradientDarkStart,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SkillSwap',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.gradientDarkStart,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Exchange Knowledge',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
