// ignore_for_file: use_null_aware_elements

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import 'package:skillswap/models/top_user_model.dart';
import 'package:skillswap/models/paginated_response.dart';
import '../config/app_config.dart';
import 'package:skillswap/services/auth_service.dart';

class SkillService {
  static const String _skillsEndpoint = '${AppConfig.baseUrl}/api/skills';
  static const String _categoriesEndpoint =
      '${AppConfig.baseUrl}/api/categories';
  static const String _searchEndpoint = '${AppConfig.baseUrl}/api/search';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // ─── Fetch Skills ─────────────────────────────────────────────
  Future<List<SkillCardData>> fetchSkills() async {
    debugPrint('SkillService: Fetching skills from $_skillsEndpoint...');

    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse(_skillsEndpoint), headers: headers)
        .timeout(const Duration(seconds: 15));

    debugPrint('SkillService.fetchSkills response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load skills (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    // ✅ Handle both Map & List safely
    final List<dynamic> raw = decoded is Map
        ? (decoded['skills'] ?? [])
        : (decoded is List ? decoded : []);

    return raw
        .map((item) => SkillCardData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─── CREATE SKILL ─────────────────────────────────────────────
  Future<SkillCardData> createSkill({
    required String token,
    required String name,
    required int categoryId,
    required String type,
    String? description,
    String? level,
  }) async {
    final response = await http
        .post(
          Uri.parse(_skillsEndpoint),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'name': name,
            'category_id': categoryId,
            'type': type,
            'description': description,
            'level': level ?? 'beginner',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create skill: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final skillJson = decoded is Map
        ? (decoded['skill'] ?? decoded['data'] ?? decoded)
        : decoded;

    return SkillCardData.fromJson(skillJson as Map<String, dynamic>);
  }

  // ─── UPDATE SKILL ─────────────────────────────────────────────
  Future<SkillCardData> updateSkill({
    required String token,
    required int skillId,
    String? name,
    int? categoryId,
    String? type,
    String? description,
    String? level,
  }) async {
    final Map<String, dynamic> bodyMap = {
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (level != null) 'level': level,
    };

    final response = await http
        .put(
          Uri.parse('$_skillsEndpoint/$skillId'),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update skill: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final skillJson = decoded is Map
        ? (decoded['skill'] ?? decoded['data'] ?? decoded)
        : decoded;

    return SkillCardData.fromJson(skillJson as Map<String, dynamic>);
  }

  // ─── DELETE SKILL ─────────────────────────────────────────────
  Future<void> deleteSkill({
    required String token,
    required int skillId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_skillsEndpoint/$skillId'),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete skill');
    }
  }

  // ─── FETCH MY SKILLS ──────────────────────────────────────────
  Future<List<SkillCardData>> fetchMySkills({required String token}) async {
    final response = await http
        .get(
          Uri.parse(_skillsEndpoint),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch skills (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> raw = decoded is Map
        ? (decoded['skills'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);

    return raw
        .map((item) => SkillCardData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─── Fetch Categories ─────────────────────────────────────────
  Future<List<CategoryModel>> fetchCategories() async {
    debugPrint('SkillService: Fetching categories...');

    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse(_categoriesEndpoint), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> raw = decoded is Map
        ? (decoded['categories'] ?? [])
        : [];

    return raw.map((item) => CategoryModel.fromJson(item)).toList();
  }

  // ─── Search Skills ────────────────────────────────────────────
  Future<PaginatedResponse<SearchResultModel>> searchSkills({
    required String query,
    int? categoryId,
    String? type,
    int page = 1,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      throw ArgumentError('Search query must be at least 2 characters long.');
    }

    final queryParams = <String, String>{
      'q': cleanQuery,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      'page': page.toString(),
    };

    final uri = Uri.parse(
      _searchEndpoint,
    ).replace(queryParameters: queryParams);

    debugPrint('SkillService: Searching → $uri');

    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['results'] ?? decoded['users'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);
    final list = raw.map((item) => SearchResultModel.fromJson(item as Map<String, dynamic>)).toList();

    final mapDecoded = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    return PaginatedResponse<SearchResultModel>.fromJson(mapDecoded, list);
  }

  // ─── Fetch Top Users by Category ──────────────────────────────
  Future<PaginatedResponse<TopUserModel>> fetchTopUsers(
    int categoryId, {
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/categories/$categoryId/users?page=$page',
    );
    debugPrint('SkillService: Fetching top users → $uri');

    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['users'] ?? decoded['results'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);
    final list = raw.map((item) => TopUserModel.fromJson(item as Map<String, dynamic>)).toList();

    final mapDecoded = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    return PaginatedResponse<TopUserModel>.fromJson(mapDecoded, list);
  }

  // Helper method to handle API errors and extract user-friendly messages
  void _handleErrorResponse(http.Response response) {
    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        } else if (decoded.containsKey('error')) {
          errorMessage = decoded['error'].toString();
        } else if (decoded.containsKey('errors')) {
          final errors = decoded['errors'];
          if (errors is Map) {
            errorMessage = errors.values.map((e) {
              if (e is List) return e.join(', ');
              return e.toString();
            }).join('\n');
          } else {
            errorMessage = errors.toString();
          }
        }
      }
    } catch (_) {
      // JSON parsing failed, use fallback message
    }

    if (response.statusCode == 404) {
      throw Exception('Resource not found: $errorMessage');
    } else if (response.statusCode == 422) {
      throw Exception('Validation error: $errorMessage');
    } else {
      throw Exception(errorMessage);
    }
  }
}
