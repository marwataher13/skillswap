import 'package:flutter/foundation.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Number of conversations that have at least one unread message
  /// — used by the nav-bar badge.
  int get unreadChatsCount =>
      _conversations.where((c) => c.unreadCount > 0).length;

  int get unreadConversationsCount =>
      _conversations.where((c) => c.unreadCount > 0).length;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadConversations({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _service.fetchConversations(),
        _service.fetchUnreadCount(),
      ]);
      final rawConvs = results[0] as List<ConversationModel>;
      final totalUnread = results[1] as int;

      final unreadConvs = rawConvs.where((c) => c.unreadCount > 0).toList();

      if (unreadConvs.length == 1 && totalUnread > 0) {
        final targetId = unreadConvs.first.id;
        _conversations = rawConvs.map((c) {
          if (c.id == targetId) {
            return c.copyWith(unreadMessagesCount: totalUnread, unreadCount: totalUnread);
          }
          return c;
        }).toList();
      } else {
        _conversations = rawConvs;
      }
      
      _error = null;
    } catch (e) {
      if (!silent) {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
      debugPrint('ChatProvider.loadConversations error: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<ConversationModel> getOrCreateAndOpenConversation(
      int otherUserId, int swapRequestId) async {
    try {
      final conv = await _service.getOrCreateConversation(
        otherUserId: otherUserId,
        swapRequestId: swapRequestId,
      );
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

  /// Instantly zeros the unread count for [conversationId] in memory so the
  /// badge clears without waiting for a full API round-trip, and marks it read on the backend.
  Future<void> markConversationRead(int conversationId) async {
    final index =
        _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1 || _conversations[index].unreadCount == 0) return;
    _conversations[index] =
        _conversations[index].copyWith(unreadMessagesCount: 0, unreadCount: 0);
    notifyListeners();

    try {
      await _service.markAsRead(conversationId);
    } catch (e) {
      debugPrint('ChatProvider.markConversationRead backend error: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
