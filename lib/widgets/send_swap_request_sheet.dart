import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/swap_request_provider.dart';
import '../theme/app_theme.dart';

class SendSwapRequestSheet extends StatefulWidget {
  final int receiverId;
  final String receiverName;
  final String requestedSkillName;

  const SendSwapRequestSheet({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.requestedSkillName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int receiverId,
    required String receiverName,
    required String requestedSkillName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendSwapRequestSheet(
        receiverId: receiverId,
        receiverName: receiverName,
        requestedSkillName: requestedSkillName,
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

    final formattedMessage =
        '[Requested Skill: ${widget.requestedSkillName}]\n${_messageController.text.trim()}';

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = context.appColors.error;

    final error = await context.read<SwapRequestProvider>().send(
      receiverId: widget.receiverId,
      message: formattedMessage,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      Navigator.pop(context, true);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Swap request sent successfully! 🎉'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Send Swap Request', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'To: ${widget.receiverName}',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Describe what skills you offer and what you want to learn…',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Message is required';
                if (v.trim().length < 10) return 'Message must be at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Send Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
