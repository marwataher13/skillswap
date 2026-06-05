import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../widgets/profile_form.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/portfolio_section.dart';
import '../../theme/app_theme.dart';

/// Root screen for Edit Profile & Portfolio.
/// Wrap with [ChangeNotifierProvider<ProfileProvider>] in your router.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileScreenContent();
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: const _ProfileBody(),
      floatingActionButton: _AddFileFab(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Edit Profile',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Scrollable body ────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isLoading;

    if (isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Avatar ──
          const ProfileAvatar(),
          const SizedBox(height: 28),

          // ── Info form ──
          const ProfileForm(),
          const SizedBox(height: 28),

          // ── Portfolio ──
          _sectionLabel('Portfolio'),
          const SizedBox(height: 12),
          const PortfolioSection(),

          // FAB clearance
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Add File FAB ───────────────────────────────────────────────────────────────

class _AddFileFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddFilePicker(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Add File',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      elevation: 4,
    );
  }

  void _showAddFilePicker(BuildContext context) {
    final provider = context.read<ProfileProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add to Portfolio',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a file type to browse from your device',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _pickerOption(
              context,
              provider,
              ctx,
              label: 'Browse Image (.png, .jpg)',
              type: FileType.image,
            ),
            const SizedBox(height: 10),
            _pickerOption(
              context,
              provider,
              ctx,
              label: 'Browse PDF Document (.pdf)',
              type: FileType.pdf,
            ),
            const SizedBox(height: 10),
            _pickerOption(
              context,
              provider,
              ctx,
              label: 'Browse Word Document (.docx)',
              type: FileType.word,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(
    BuildContext parentContext,
    ProfileProvider provider,
    BuildContext sheetContext, {
    required String label,
    required FileType type,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(sheetContext); // Close sheet
        final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
        
        final extensions = switch (type) {
          FileType.image => ['png', 'jpg', 'jpeg'],
          FileType.pdf => ['pdf'],
          FileType.word => ['doc', 'docx'],
        };

        try {
          final result = await fp.FilePicker.platform.pickFiles(
            type: fp.FileType.custom,
            allowedExtensions: extensions,
            withData: true,
          );

          if (result == null || result.files.isEmpty) {
            return; // User cancelled
          }

          final file = result.files.first;
          final name = file.name;
          Uint8List? bytes = file.bytes;

          if (bytes == null && file.path != null) {
            bytes = io.File(file.path!).readAsBytesSync();
          }

          if (bytes == null) {
            throw Exception('Failed to read selected file bytes');
          }

          // Open the naming dialog
          if (!parentContext.mounted) return;
          final customTitle = await _showNameFileDialog(parentContext, name, type);
          if (customTitle == null) {
            return; // User cancelled the naming dialog
          }

          final item = PortfolioItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: customTitle,
            type: type,
          );

          await provider.addPortfolioItem(item, bytes);
          
          scaffoldMessenger.showSnackBar(
            _snackBar('"$customTitle" added successfully ✅', isError: false),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            _snackBar('Failed to add file: $e', isError: true),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            _fileIcon(type),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileIcon(FileType type) {
    final (icon, color) = switch (type) {
      FileType.image => (LucideIcons.image, const Color(0xFF4CAF50)),
      FileType.pdf => (LucideIcons.fileText, const Color(0xFFE53935)),
      FileType.word => (LucideIcons.fileType2, const Color(0xFF1565C0)),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Future<String?> _showNameFileDialog(
    BuildContext context,
    String originalName,
    FileType type,
  ) async {
    final controller = TextEditingController(text: originalName);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: Text(
          'Name Portfolio Item',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Give your file a custom title to display in your portfolio.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (val.trim().length > 80) {
                    return 'Title must be under 80 characters';
                  }
                  return null;
                },
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter title',
                  filled: true,
                  fillColor: AppColors.primary.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx, null),
             child: Text(
               'Cancel',
               style: GoogleFonts.poppins(
                 fontWeight: FontWeight.w600,
                 color: AppColors.textSecondary,
               ),
             ),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: Text(
              'Add File',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar(String msg, {required bool isError}) => SnackBar(
    content: Text(msg),
    backgroundColor: isError
        ? const Color.fromARGB(255, 205, 36, 36)
        : AppColors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  );
}
