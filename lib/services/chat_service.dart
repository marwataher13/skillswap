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
    final url = '$_base/api/conversations';
    debugPrint('ChatService URL: GET $url');
    final headers = await _authHeaders();
    
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load conversations. URL: $url, Code: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> raw = decoded is Map
          ? (decoded['conversations'] ?? decoded['data'] ?? [])
          : (decoded is List ? decoded : []);

      return raw
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ChatService GET $url error: $e');
      rethrow;
    }
  }

  // ─── GET /conversations/{id}/messages ─────────────────────────────────────
  Future<List<MessageModel>> fetchMessages(int conversationId) async {
    final url = '$_base/api/conversations/$conversationId/messages';
    debugPrint('ChatService URL: GET $url');
    final headers = await _authHeaders();
    
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load messages. URL: $url, Code: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> raw = decoded is Map
          ? (decoded['messages'] ?? decoded['data'] ?? [])
          : (decoded is List ? decoded : []);

      return raw
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
    debugPrint('ChatService URL: POST $url');
    final headers = await _authHeaders();
    final reqBody = jsonEncode({'body': body});
    debugPrint('ChatService Request Body: $reqBody');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: reqBody,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to send message. URL: $url, Code: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final msgJson = decoded is Map
          ? (decoded['message'] ?? decoded['data'] ?? decoded)
          : decoded;

      return MessageModel.fromJson(msgJson as Map<String, dynamic>);
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
    final url = '$_base/api/conversations/$conversationId/messages/$messageId';
    debugPrint('ChatService URL: DELETE $url');
    final headers = await _authHeaders();

    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete message. URL: $url, Code: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('ChatService DELETE $url error: $e');
      rethrow;
    }
  }

  // ─── POST /conversations/get-or-create ────────────────────────────────────
  Future<ConversationModel> getOrCreateConversation(int otherUserId) async {
    final url = '$_base/api/conversations/get-or-create';
    debugPrint('ChatService URL: POST $url');
    final headers = await _authHeaders();
    final reqBody = jsonEncode({'other_user_id': otherUserId});
    debugPrint('ChatService Request Body: $reqBody');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: reqBody,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to get/create conversation. URL: $url, Code: ${response.statusCode}, Body: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final convJson = decoded is Map
          ? (decoded['conversation'] ?? decoded['data'] ?? decoded)
          : decoded;

      return ConversationModel.fromJson(convJson as Map<String, dynamic>);
    } catch (e) {
      debugPrint('ChatService POST $url error: $e');
      rethrow;
    }
  }

  // ─── GET /messages/unread-count ───────────────────────────────────────────
  Future<int> fetchUnreadCount() async {
    final url = '$_base/api/messages/unread-count';
    debugPrint('ChatService URL: GET $url');
    final headers = await _authHeaders();

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('ChatService Response Code: ${response.statusCode}');
      debugPrint('ChatService Response Body: ${response.body}');

      if (response.statusCode != 200) return 0;

      final decoded = jsonDecode(response.body);
      final count = decoded is Map
          ? (decoded['unread_count'] ?? decoded['count'] ?? 0)
          : 0;
      return int.tryParse(count.toString()) ?? 0;
    } catch (e) {
      debugPrint('ChatService GET $url error: $e');
      return 0;
    }
  }
}
