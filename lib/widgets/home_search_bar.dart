import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../theme/app_theme.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onFilterPressed;

  const HomeSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterPressed,
    this.hintText = 'Search skills or members',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppShadows.subtle,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          suffixIcon: onFilterPressed != null
              ? IconButton(
                  icon: const Icon(LucideIcons.sliders, size: 20),
                  onPressed: onFilterPressed,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
