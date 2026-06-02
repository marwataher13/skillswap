import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/chat_item_data.dart';

class ChatService {
  static const String _endpoint = '${AppConfig.baseUrl}/api/chats';

  /// Asynchronously fetch the active user chat conversations.
  /// Standard simulated latency gives a polished mockup performance in dev.
  Future<List<ChatItemData>> fetchChats() async {
    debugPrint('ChatService: Fetching chat conversations from $_endpoint...');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Returning standard mocks (can easily connect to backend endpoint via http.get later)
    return const [
      ChatItemData(
        name: 'Eleanor Pena',
        lastMessage: 'Hey! I\'d love to learn how ...',
        time: '10:45 AM',
        unreadCount: 2,
        avatarUrl: 'assets/images/user1.jpg',
      ),
      ChatItemData(
        name: 'Cameron Williamson',
        lastMessage: 'That\'s a great idea! Let\'s sch...',
        time: '9:30 AM',
        unreadCount: 0,
        avatarUrl: 'assets/images/user2.jpg',
      ),
      ChatItemData(
        name: 'Wade Warren',
        lastMessage: 'Are you free this weekend...',
        time: 'Yesterday',
        unreadCount: 0,
        avatarUrl: 'assets/images/user3.jpg',
      ),
      ChatItemData(
        name: 'Jane Cooper',
        lastMessage: 'Perfect, thanks!',
        time: 'Yesterday',
        unreadCount: 0,
        avatarUrl: 'assets/images/user4.jpg',
      ),
    ];
  }
}
