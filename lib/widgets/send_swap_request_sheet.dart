import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/swap_request_provider.dart';
import '../theme/app_theme.dart';
 
/// Call this from any screen where you want to send a swap request.
///
/// ```dart
/// SendSwapRequestSheet.show(context, receiverId: user.id, receiverName: user.name);
/// ```
class SendSwapRequestSheet extends StatefulWidget {
  final int receiverId;
  final String receiverName;
 
  const SendSwapRequestSheet({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });
 
  static Future<bool?> show(
    BuildContext context, {
    required int receiverId,
    required String receiverName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendSwapRequestSheet(
        receiverId: receiverId,
        receiverName: receiverName,
      ),
    );
  }
 
  @override
  State<SendSwapRequestSheet> createState() => _SendSwapRequestSheetState();
}
 
class _SendSwapRequestSheetState extends State<SendSwapRequestSheet> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
 
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    setState(() => _loading = true);
 
    final error = await context.read<SwapRequestProvider>().send(
          receiverId: widget.receiverId,
          message: _messageController.text.trim(),
        );
 
    if (!mounted) return;
    setState(() => _loading = false);
 
    if (error == null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Swap request sent successfully! 🎉'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
 
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
 
            // Title
            Text('Send Swap Request', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'To: ${widget.receiverName}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
 
            // Message field
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText:
                    'Describe what skills you offer and what you want to learn…',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Message is required';
                }
                if (v.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
 
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Request',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}