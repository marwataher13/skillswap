import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Field Label
// ─────────────────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String label;

  const FieldLabel(
    this.label, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom Text Field
// ─────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;

  final Widget? suffixIcon;

  final bool obscureText;

  final TextEditingController? controller;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,

      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        prefixIcon: Icon(
          prefixIcon,
          size: 20,
        ),

        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// elevated buttom
// ─────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppSpacing.radiusMd,
        ),
        boxShadow: AppShadows.button,
      ),

      child: ElevatedButton(
        onPressed: onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          elevation: 0,

          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusMd,
            ),
          ),
        ),

        child: Text(
          label,

          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.surface,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Social Button
// ─────────────────────────────────────────────────────────────
class SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(
        AppSpacing.radiusMd,
      ),

      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        decoration: BoxDecoration(
          color: AppColors.surface,

          borderRadius: BorderRadius.circular(
            AppSpacing.radiusMd,
          ),

          border: Border.all(
            color: AppColors.border,
          ),

          boxShadow: AppShadows.subtle,
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Image.asset(
              assetPath,
              width: 22,
              height: 22,
            ),

            const SizedBox(width: 12),

            Text(
              label,

              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Divider
// ─────────────────────────────────────────────────────────────
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({
    super.key,
    this.label = 'Or continue with',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),

          child: Text(
            label,

            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Auth Tab Switcher
// ─────────────────────────────────────────────────────────────
class AuthTabSwitcher extends StatelessWidget {
  final int selectedIndex;

  final Function(int) onTabSelected;

  const AuthTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,

        borderRadius: BorderRadius.circular(
          AppSpacing.radiusFull,
        ),
      ),

      child: Row(
        children: [
          _buildTab(
            title: 'Log In',
            index: 0,
          ),

          _buildTab(
            title: 'Sign Up',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required int index,
  }) {
    final isSelected =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 250,
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),

          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,

            borderRadius: BorderRadius.circular(
              AppSpacing.radiusFull,
            ),

            boxShadow: isSelected
                ? AppShadows.button
                : [],
          ),

          child: Center(
            child: Text(
              title,

              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,

                color: isSelected
                    ? AppColors.surface
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}