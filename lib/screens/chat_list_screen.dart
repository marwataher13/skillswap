import 'package:flutter/material.dart';
import '../models/chat_item_data.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_card.dart';
import '../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  List<ChatItemData> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _chatService.fetchChats();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chats: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // الهيدر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Search chats feature coming soon! 🔍'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  Text('Chats', style: AppTextStyles.headlineMedium),
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('New conversation creation coming soon! 💬'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // القائمة
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        color: AppColors.primaryDark,
                        child: _chats.isEmpty
                            ? Center(
                                child: Text(
                                  'No chats found.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _chats.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final chat = _chats[index];
                                  return ChatCard(
                                    chatItem: chat,
                                    onTap: () {},
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
