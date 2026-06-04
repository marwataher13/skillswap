import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/models/skill_card_data.dart';
import 'package:skillswap/models/category_model.dart';
import 'package:skillswap/models/search_result_model.dart';
import '../config/app_config.dart';

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

    final response = await http
        .get(Uri.parse(_skillsEndpoint), headers: _headers)
        .timeout(const Duration(seconds: 15));

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

    if (response.statusCode != 201) {
      throw Exception('Failed to create skill: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    return SkillCardData.fromJson(decoded['skill']);
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
    final response = await http
        .put(
          Uri.parse('$_skillsEndpoint/$skillId'),
          headers: {..._headers, 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            if (name != null) 'name': name,
            if (categoryId != null) 'category_id': categoryId,
            if (type != null) 'type': type,
            if (description != null) 'description': description,
            if (level != null) 'level': level,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to update skill: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    return SkillCardData.fromJson(decoded['skill']);
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

    if (response.statusCode != 200) {
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
      throw Exception('Failed to fetch skills');
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> raw = decoded['skills'] ?? [];

    return raw.map((item) => SkillCardData.fromJson(item)).toList();
  }

  // ─── Fetch Categories ─────────────────────────────────────────
  Future<List<CategoryModel>> fetchCategories() async {
    debugPrint('SkillService: Fetching categories...');

    final response = await http
        .get(Uri.parse(_categoriesEndpoint), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed categories (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> raw = decoded is Map
        ? (decoded['categories'] ?? [])
        : [];

    return raw.map((item) => CategoryModel.fromJson(item)).toList();
  }

  // ─── Search Skills ────────────────────────────────────────────
  Future<List<SearchResultModel>> searchSkills({
    required String query,
    int? categoryId,
    String? type,
  }) async {
    final queryParams = <String, String>{
      if (query.isNotEmpty) 'q': query,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
    };

    final uri = Uri.parse(
      _searchEndpoint,
    ).replace(queryParameters: queryParams);

    debugPrint('SkillService: Searching → $uri');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Search failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> raw = decoded is Map ? (decoded['results'] ?? []) : [];

    return raw.map((item) => SearchResultModel.fromJson(item)).toList();
  }
}
