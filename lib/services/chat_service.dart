import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/models/message_model.dart';
import 'package:skillswap/services/auth_service.dart';

class ChatService {
  static const String _base = AppConfig.baseUrl;

  /// Reads the current user ID from the local cache set by [ProfileProvider].
  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_user_id') ?? 0;
  }

  // ─── GET /conversations ───────────────────────────────────────────────────

  Future<List<ConversationModel>> fetchConversations() async {
    final url = '$_base/api/conversations';
    final headers = await AuthService.getAuthHeaders();
    final currentUserId = await _getCurrentUserId();

    debugPrint('ChatService: GET $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService: ${response.statusCode} body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load conversations (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> raw = decoded is Map
          ? (decoded['conversations'] ?? decoded['data'] ?? [])
          : (decoded is List ? decoded : []);

      return raw
          .map((e) => ConversationModel.fromJson(
              e as Map<String, dynamic>, currentUserId))
          .toList();
    } catch (e) {
      debugPrint('ChatService GET $url error: $e');
      rethrow;
    }
  }

  // ─── GET /conversations/{id}/messages ─────────────────────────────────────

  Future<List<MessageModel>> fetchMessages(int conversationId) async {
    final url = '$_base/api/conversations/$conversationId/messages';
    final headers = await AuthService.getAuthHeaders();
    final currentUserId = await _getCurrentUserId();

    debugPrint('ChatService: GET $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load messages (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final messagesObj = decoded['messages'] ?? decoded['data'];
      final List<dynamic> raw =
          (messagesObj is Map && messagesObj.containsKey('data'))
              ? (messagesObj['data'] as List<dynamic>? ?? [])
              : (messagesObj is List ? messagesObj : []);

      final list = raw
          .map((e) => MessageModel.fromJson(
              e as Map<String, dynamic>, currentUserId))
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      return list;
    } catch (e) {
      debugPrint('ChatService GET $url error: $e');
      rethrow;
    }
  }

  // ─── POST /conversations/{id}/messages ────────────────────────────────────

  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final url = '$_base/api/conversations/$conversationId/messages';
    final headers = await AuthService.getAuthHeaders();
    final currentUserId = await _getCurrentUserId();

    debugPrint('ChatService: POST $url');
    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode({'body': body}))
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send message (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final msgJson = decoded is Map
          ? (decoded['data'] ??
              (decoded['message'] is Map ? decoded['message'] : null) ??
              decoded)
          : decoded;

      return MessageModel.fromJson(
          msgJson as Map<String, dynamic>, currentUserId);
    } catch (e) {
      debugPrint('ChatService POST $url error: $e');
      rethrow;
    }
  }

  // ─── DELETE /conversations/{convId}/messages/{msgId} ─────────────────────

  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
  }) async {
    final url =
        '$_base/api/conversations/$conversationId/messages/$messageId';
    final headers = await AuthService.getAuthHeaders();

    debugPrint('ChatService: DELETE $url');
    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to delete message (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('ChatService DELETE $url error: $e');
      rethrow;
    }
  }

  // ─── POST /conversations/get-or-create ────────────────────────────────────

  Future<ConversationModel> getOrCreateConversation({
    required int otherUserId,
    required int swapRequestId,
  }) async {
    final url = '$_base/api/conversations/get-or-create';
    final headers = await AuthService.getAuthHeaders();
    final currentUserId = await _getCurrentUserId();

    debugPrint('ChatService: POST $url');
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({
              'other_user_id': otherUserId,
              'swap_request_id': swapRequestId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Failed to get/create conversation (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final convJson = decoded is Map
          ? (decoded['conversation'] ?? decoded['data'] ?? decoded)
          : decoded;

      return ConversationModel.fromJson(
          convJson as Map<String, dynamic>, currentUserId);
    } catch (e) {
      debugPrint('ChatService POST $url error: $e');
      rethrow;
    }
  }

  // ─── POST /conversations/{id}/read ───────────────────────────────────────

  Future<void> markAsRead(int conversationId) async {
    final url = '$_base/api/conversations/$conversationId/read';
    final headers = await AuthService.getAuthHeaders();

    try {
      await http
          .post(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('ChatService markAsRead error: $e');
    }
  }

  // ─── GET /messages/unread-count ───────────────────────────────────────────

  Future<int> fetchUnreadCount() async {
    final url = '$_base/api/messages/unread-count';
    final headers = await AuthService.getAuthHeaders();

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return 0;

      final decoded = jsonDecode(response.body);
      final count = decoded is Map
          ? (decoded['unread_count'] ?? decoded['count'] ?? 0)
          : 0;
      return int.tryParse(count.toString()) ?? 0;
    } catch (e) {
      debugPrint('ChatService fetchUnreadCount error: $e');
      return 0;
    }
  }
}
