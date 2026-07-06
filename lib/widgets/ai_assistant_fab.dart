import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ai_icon_painter.dart';

class AiAssistantFab extends StatefulWidget {
  const AiAssistantFab({super.key});

  @override
  State<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends State<AiAssistantFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;
  late Animation<double> _glowOpacityAnimation;
  double _pressScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowOpacityAnimation = Tween<double>(begin: 0.15, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() {
      _pressScale = 0.92;
    });
  }

  void _onTapUp() {
    setState(() {
      _pressScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const double buttonSize = 56.0;

    return AnimatedScale(
      scale: _pressScale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _breathAnimation.value;
          final glowOpacity = _glowOpacityAnimation.value;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer Breathing Glow Aura
              Transform.scale(
                scale: scale,
                child: Container(
                  width: buttonSize + 16,
                  height: buttonSize + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primary.withValues(alpha: glowOpacity),
                  ),
                ),
              ),
              // Main Button Container
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.button,
                  gradient: LinearGradient(
                    colors: [c.gradientStart, c.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    splashColor: Colors.white.withValues(alpha: 0.25),
                    highlightColor: Colors.white.withValues(alpha: 0.15),
                    onTapDown: (_) => _onTapDown(),
                    onTapUp: (_) => _onTapUp(),
                    onTapCancel: () => _onTapUp(),
                    onTap: () {
                      Navigator.pushNamed(context, '/ai-chat');
                    },
                    child: Center(
                      child: CustomPaint(
                        size: const Size(26, 26),
                        painter: const AiIconPainter(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
