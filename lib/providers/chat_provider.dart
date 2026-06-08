import 'package:flutter/foundation.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Load conversations from the API
  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final list = await _service.fetchConversations();
      _conversations = list;
      _error = null;
      await loadUnreadCount();
    } catch (e) {
      if (!silent) {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
      debugPrint('ChatProvider.loadConversations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieve unread counts
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.fetchUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider.loadUnreadCount error: $e');
    }
  }

  /// Get or create a conversation with the target other user
  Future<ConversationModel> getOrCreateAndOpenConversation(int otherUserId) async {
    try {
      final conv = await _service.getOrCreateConversation(otherUserId);
      final index = _conversations.indexWhere((c) => c.id == conv.id);
      if (index == -1) {
        _conversations.insert(0, conv);
      } else {
        _conversations[index] = conv;
      }
      notifyListeners();
      return conv;
    } catch (e) {
      debugPrint('ChatProvider.getOrCreateAndOpenConversation error: $e');
      rethrow;
    }
  }

  /// Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
