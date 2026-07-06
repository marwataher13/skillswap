import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/assistant_model.dart';
import 'package:skillswap/services/auth_service.dart';

class AssistantService {
  static const String _base = AppConfig.baseUrl;

  // POST /api/assistant/chat
  Future<AiMessage> chat({required String message, int? conversationId}) async {
    final url = '$_base/api/assistant/chat';
    final headers = await AuthService.getAuthHeaders();
    final body = jsonEncode({
      'message': message,
      'conversation_id': conversationId,
    });

    debugPrint('AssistantService POST $url body: $body');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService POST $url response: ${response.statusCode} body: ${response.body}');
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message: (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    return AiMessage.fromJson(decoded);
  }

  // GET /api/assistant/conversations
  Future<List<AiConversation>> fetchConversations() async {
    final url = '$_base/api/assistant/conversations';
    final headers = await AuthService.getAuthHeaders();

    debugPrint('AssistantService GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService GET $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch conversations (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded['conversations'] ?? decoded['data'] ?? [];
    return raw.map((e) => AiConversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/assistant/conversations/{id}
  Future<List<AiMessage>> fetchMessages(int conversationId) async {
    final url = '$_base/api/assistant/conversations/$conversationId';
    final headers = await AuthService.getAuthHeaders();

    debugPrint('AssistantService GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService GET $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch conversation messages (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final conversationObj = decoded['conversation'] ?? decoded['data'] ?? {};
    final List<dynamic> rawMessages = conversationObj['messages'] ?? [];
    return rawMessages.map((e) => AiMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  // DELETE /api/assistant/conversations/{id}
  Future<void> deleteConversation(int conversationId) async {
    final url = '$_base/api/assistant/conversations/$conversationId';
    final headers = await AuthService.getAuthHeaders();

    debugPrint('AssistantService DELETE $url');
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService DELETE $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete conversation (${response.statusCode})');
    }
  }

  // POST /api/assistant/career/recommend
  Future<List<CareerRecommendation>> recommendCareer(Map<String, int> assessment) async {
    final url = '$_base/api/assistant/career/recommend';
    final headers = await AuthService.getAuthHeaders();
    final body = jsonEncode({
      'assessment': assessment,
    });

    debugPrint('AssistantService POST $url body: $body');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService POST $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to recommend career (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded['careers'] ?? decoded['data'] ?? [];
    return raw.map((e) => CareerRecommendation.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /api/assistant/skill-gap
  Future<SkillGap> fetchSkillGap(String career) async {
    final url = '$_base/api/assistant/skill-gap';
    final headers = await AuthService.getAuthHeaders();
    final body = jsonEncode({
      'career': career,
    });

    debugPrint('AssistantService POST $url body: $body');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService POST $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to fetch skill gap (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    return SkillGap.fromJson(decoded);
  }

  // POST /api/assistant/roadmap
  Future<List<RoadmapStep>> fetchRoadmap(String career, List<String> missingSkills) async {
    final url = '$_base/api/assistant/roadmap';
    final headers = await AuthService.getAuthHeaders();
    final body = jsonEncode({
      'career': career,
      'missing_skills': missingSkills,
    });

    debugPrint('AssistantService POST $url body: $body');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 300));

    debugPrint('AssistantService POST $url response: ${response.statusCode} body: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to fetch roadmap (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded['roadmap'] ?? decoded['data'] ?? (decoded is List ? decoded : []);
    return raw.map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>)).toList();
  }
}
