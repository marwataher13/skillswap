import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/providers/profile_provider.dart';
import '../theme/app_theme.dart';

/// Renders the portfolio as a 2-column [GridView].
/// Each tile shows file type icon, title, and a delete button.
class PortfolioSection extends StatelessWidget {
  final bool isEditable;
  final List<PortfolioItem>? items;
  const PortfolioSection({super.key, this.isEditable = true, this.items});

  @override
  Widget build(BuildContext context) {
    final list = items ?? context.watch<ProfileProvider>().portfolioItems;

    if (list.isEmpty) return _EmptyPortfolio(isEditable: isEditable);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) =>
          _PortfolioTile(item: list[index], isEditable: isEditable),
    );
  }
}

// ── Single portfolio tile ──────────────────────────────────────────────────────

class _PortfolioTile extends StatelessWidget {
  final PortfolioItem item;
  final bool isEditable;
  const _PortfolioTile({required this.item, required this.isEditable});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolveType(item.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => _viewFile(context),
          child: Stack(
            children: [
              // ── Main content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 24, color: color),
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Type badge
                      Text(
                        _typeLabel(item.type),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Delete button ──
              if (isEditable)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.trash2,
                          size: 13, color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _FileViewerDialog(item: item),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        backgroundColor: AppColors.surface,
        title: Text('Remove File',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'Remove "${item.title}" from your portfolio?',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await context.read<ProfileProvider>().deletePortfolioItem(item.id);
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('"${item.title}" removed successfully ✅',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } catch (e) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove "${item.title}": $e',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: Text('Remove',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _resolveType(FileType type) => switch (type) {
        FileType.image => (LucideIcons.image,    const Color(0xFF4CAF50)),
        FileType.pdf   => (LucideIcons.fileText, const Color(0xFFE53935)),
        FileType.word  => (LucideIcons.fileType2, const Color(0xFF1565C0)),
      };

  String _typeLabel(FileType type) => switch (type) {
        FileType.image => 'IMAGE',
        FileType.pdf   => 'PDF',
        FileType.word  => 'WORD',
      };
}

class _FileViewerDialog extends StatelessWidget {
  final PortfolioItem item;
  const _FileViewerDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolveType(item.type);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.type.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            
            // Viewer Body
            Flexible(
              child: SingleChildScrollView(
                child: _buildViewerContent(context),
              ),
            ),
            
            const Divider(height: 24, thickness: 1),
            
            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sharing "${item.title}"…', style: GoogleFonts.poppins(fontSize: 13)),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: Text(
                      'Share',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloaded "${item.title}" successfully! 📥', style: GoogleFonts.poppins(fontSize: 13)),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.download, size: 16),
                    label: Text(
                      'Download',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerContent(BuildContext context) {
    if (item.type == FileType.image) {
      if (item.fileUrl != null && item.fileUrl!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            item.fileUrl!,
            fit: BoxFit.contain,
            headers: const {
              'ngrok-skip-browser-warning': 'true',
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 240,
                color: AppColors.primary.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildMockImageContent(),
          ),
        );
      }
      return _buildMockImageContent();
    } else if (item.type == FileType.pdf) {
      return _buildMockPdfContent();
    } else {
      return _buildMockWordContent();
    }
  }

  Widget _buildMockImageContent() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.image, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              'Image Preview',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockPdfContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOCUMENT READER',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Page 1 of 3',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '1. Introduction & Overview',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This portfolio item contains detailed project briefs, architectural blueprints, and flow diagram schemes developed during the product redesign phase. The redesign goals were to enhance accessibility and user retention.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '2. Core Design Principles',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Simplicity: Removing unnecessary visual components.\n• Feedback: Providing clear response cues for user actions.\n• Speed: Optimizing widget load times and API requests.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockWordContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.fileType2, size: 14, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                'WORD DOCUMENT PREVIEW',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This Word document holds case study results, metrics logs, and descriptive guidelines detailing team structure and development workflows. You can download this file to open it in Microsoft Word or Google Docs.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _resolveType(FileType type) => switch (type) {
        FileType.image => (LucideIcons.image,    const Color(0xFF4CAF50)),
        FileType.pdf   => (LucideIcons.fileText, const Color(0xFFE53935)),
        FileType.word  => (LucideIcons.fileType2, const Color(0xFF1565C0)),
      };
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyPortfolio extends StatelessWidget {
  final bool isEditable;
  const _EmptyPortfolio({this.isEditable = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.folderOpen,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            isEditable ? 'No files yet' : 'No portfolio files',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEditable ? 'Tap "Add File" to upload your work' : 'This user has not uploaded any files yet.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}