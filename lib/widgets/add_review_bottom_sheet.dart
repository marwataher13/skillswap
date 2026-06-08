import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/providers/review_provider.dart';
import 'package:skillswap/theme/app_theme.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final int userId;
  final int swapRequestId;
  final VoidCallback onSaved;

  const AddReviewBottomSheet({
    super.key,
    required this.userId,
    required this.swapRequestId,
    required this.onSaved,
  });

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ReviewProvider>();

    try {
      await provider.createReview(
        userId: widget.userId,
        swapRequestId: widget.swapRequestId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      
      _showSuccess('Review added successfully!');
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title Header
              Text('Write a Review', style: AppTextStyles.headlineMedium),
              Text(
                'Share your experience with this user',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Star Rating Row Title
              _buildLabel('Rating Score'),
              const SizedBox(height: 12),

              // Interactive Star Rating Builder
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starVal = index + 1.0;
                    final isFilled = starVal <= _rating;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starVal;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isFilled ? Colors.amber : AppColors.textHint.withValues(alpha: 0.4),
                          size: 44,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),

              // Review Comments Form Field
              _buildLabel('Your Review'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Describe your exchange experience, helpfulness, and support details...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.rate_review_outlined),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a comments description';
                  }
                  if (v.trim().length < 5) {
                    return 'Review description must be at least 5 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),

              // Save Action Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
