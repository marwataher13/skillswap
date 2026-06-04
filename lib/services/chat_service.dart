import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/conversation_model.dart';
import 'package:skillswap/models/message_model.dart';

class ChatService {
  static const String _base = AppConfig.baseUrl;

  // ─── Auth Header ─────────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // ─── GET /conversations ───────────────────────────────────────────────────
  Future<List<ConversationModel>> fetchConversations() async {
    debugPrint('ChatService: Fetching conversations...');
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$_base/api/conversations'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load conversations (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['conversations'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);

    return raw
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── GET /conversations/{id}/messages ─────────────────────────────────────
  Future<List<MessageModel>> fetchMessages(int conversationId) async {
    debugPrint('ChatService: Fetching messages for conv $conversationId...');
    final headers = await _authHeaders();
    final response = await http
        .get(
          Uri.parse('$_base/api/conversations/$conversationId/messages'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['messages'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);

    return raw
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── POST /conversations/{id}/messages ────────────────────────────────────
  Future<MessageModel> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    debugPrint('ChatService: Sending message to conv $conversationId...');
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$_base/api/conversations/$conversationId/messages'),
          headers: headers,
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final msgJson = decoded is Map
        ? (decoded['message'] ?? decoded['data'] ?? decoded)
        : decoded;

    return MessageModel.fromJson(msgJson as Map<String, dynamic>);
  }

  // ─── DELETE /conversations/{convId}/messages/{msgId} ─────────────────────
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
  }) async {
    debugPrint('ChatService: Deleting message $messageId...');
    final headers = await _authHeaders();
    final response = await http
        .delete(
          Uri.parse(
            '$_base/api/conversations/$conversationId/messages/$messageId',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete message (${response.statusCode})');
    }
  }

  // ─── POST /conversations/get-or-create ────────────────────────────────────
  Future<ConversationModel> getOrCreateConversation(int otherUserId) async {
    debugPrint(
      'ChatService: Get/create conversation with user $otherUserId...',
    );
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$_base/api/conversations/get-or-create'),
          headers: headers,
          body: jsonEncode({'other_user_id': otherUserId}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to get/create conversation (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final convJson = decoded is Map
        ? (decoded['conversation'] ?? decoded['data'] ?? decoded)
        : decoded;

    return ConversationModel.fromJson(convJson as Map<String, dynamic>);
  }

  // ─── GET /messages/unread-count ───────────────────────────────────────────
  Future<int> fetchUnreadCount() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$_base/api/messages/unread-count'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return 0;

    final decoded = jsonDecode(response.body);
    return (decoded['unread_count'] ?? decoded['count'] ?? 0) as int;
  }
}
