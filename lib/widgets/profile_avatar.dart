import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:skillswap/providers/profile_provider.dart';
import '../theme/app_theme.dart';

/// Displays the user's avatar with an edit pencil badge.
/// Tapping the badge opens an [_AvatarOptionsSheet].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Avatar circle ──
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      headers: const {
                        'ngrok-skip-browser-warning': 'true',
                      },
                      errorBuilder: (context, error, stackTrace) => _initials(profile.name),
                    ),
                  )
                : _initials(profile.name),
          ),

          // ── Edit badge ──
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showAvatarOptions(context, provider),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.pencil,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarOptionsSheet(provider: provider),
    );
  }
}

// ── Avatar options bottom sheet ───────────────────────────────────────────────

class _AvatarOptionsSheet extends StatelessWidget {
  final ProfileProvider provider;
  const _AvatarOptionsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Profile Picture',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Upload option
          _OptionTile(
            icon: LucideIcons.upload,
            label: 'Upload New Picture',
            iconBg: AppColors.primary.withValues(alpha: 0.08),
            iconColor: AppColors.primary,
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  withData: true,
                );

                if (result == null || result.files.isEmpty) {
                  return;
                }

                final file = result.files.first;
                Uint8List? bytes = file.bytes;
                final filename = file.name;

                if (bytes == null && file.path != null) {
                  bytes = io.File(file.path!).readAsBytesSync();
                }

                if (bytes == null) {
                  throw Exception('Failed to read file bytes');
                }

                navigator.pop();
                await provider.uploadAvatar(bytes, filename);
                
                scaffoldMessenger.showSnackBar(
                  _snackBar('Profile picture updated ✅', isError: false),
                );
              } catch (e) {
                if (navigator.canPop()) {
                  navigator.pop();
                }
                scaffoldMessenger.showSnackBar(
                  _snackBar('Failed to upload picture: $e', isError: true),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          // Delete option
          _OptionTile(
            icon: LucideIcons.trash2,
            label: 'Delete Current Picture',
            iconBg: AppColors.error.withValues(alpha: 0.08),
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: () async {
              Navigator.pop(context);
              try {
                await provider.deleteAvatar();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Profile picture removed', isError: false),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  _snackBar('Failed to remove picture: $e', isError: true),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar(String msg, {required bool isError}) => SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color.fromARGB(255, 205, 36, 36) : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}