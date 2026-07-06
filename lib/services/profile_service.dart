import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/services/auth_service.dart';

/// Service class interfacing with backend REST API endpoints
/// for profile settings and portfolio files.
class ProfileService {
  static const String _baseUrl = AppConfig.baseUrl;

  // 1. GET /api/profile
  Future<ProfileData> fetchProfile() async {
    final url = Uri.parse('$_baseUrl/api/profile');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      debugPrint('=== FETCH PROFILE RESPONSE ===');
      debugPrint('Response: ${response.body}');
      final data = jsonDecode(response.body);
      final profileJson = data is Map && data.containsKey('data') ? data['data'] : data;
      final resultMap = Map<String, dynamic>.from(profileJson as Map);
      if (data is Map) {
        for (final key in ['trust_score', 'average_rating', 'total_swaps']) {
          if (data.containsKey(key) && !resultMap.containsKey(key)) {
            resultMap[key] = data[key];
          }
        }
      }
      return ProfileData.fromJson(resultMap);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode} ${response.body}');
    }
  }

  // 1b. GET /api/users/{id}
  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final url = Uri.parse('$_baseUrl/api/users/$userId');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      debugPrint('=== FETCH USER PROFILE RESPONSE ===');
      debugPrint('Response: ${response.body}');
      final data = jsonDecode(response.body);
      final userJson = data is Map && data.containsKey('user') ? data['user'] : data;
      final resultMap = Map<String, dynamic>.from(userJson as Map);
      if (data is Map) {
        for (final key in ['trust_score', 'average_rating', 'total_swaps']) {
          if (data.containsKey(key) && !resultMap.containsKey(key)) {
            resultMap[key] = data[key];
          }
        }
      }
      return resultMap;
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode} ${response.body}');
    }
  }

  // 2. PUT /api/profile/update
  Future<ProfileData> updateProfile(ProfileData profile) async {
    final url = Uri.parse('$_baseUrl/api/profile/update');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(profile.toJson()),
    ).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      debugPrint('=== UPDATE PROFILE RESPONSE ===');
      debugPrint('Response: ${response.body}');
      final data = jsonDecode(response.body);
      final profileJson = data is Map && data.containsKey('data') ? data['data'] : data;
      final resultMap = Map<String, dynamic>.from(profileJson as Map);
      if (data is Map) {
        for (final key in ['trust_score', 'average_rating', 'total_swaps']) {
          if (data.containsKey(key) && !resultMap.containsKey(key)) {
            resultMap[key] = data[key];
          }
        }
      }
      return ProfileData.fromJson(resultMap);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode} ${response.body}');
    }
  }

  // 3. POST /api/profile/picture
  Future<String> uploadProfilePicture(Uint8List bytes, String filename) async {
    final url = Uri.parse('$_baseUrl/api/profile/picture');
    final headers = await AuthService.getAuthHeaders();
    
    final request = http.MultipartRequest('POST', url);
    headers.forEach((key, value) {
      request.headers[key] = value;
    });
    
    final multipartFile = http.MultipartFile.fromBytes(
      'profile_picture',
      bytes,
      filename: filename,
    );
    request.files.add(multipartFile);
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('=== UPLOAD PROFILE PICTURE RESPONSE ===');
      debugPrint('Response: ${response.body}');
      final data = jsonDecode(response.body);
      final parsed = data is Map && data.containsKey('data') ? data['data'] : data;
      
      String? resolvedUrl;
      if (parsed is Map) {
        final avatarVal = parsed['profile_picture'] ?? parsed['avatar_url'] ?? parsed['avatar'] ?? parsed['url'] ?? parsed['file_url'] ?? parsed['path'];
        if (avatarVal is String) {
          resolvedUrl = avatarVal;
        } else if (avatarVal is Map) {
          resolvedUrl = avatarVal['profile_picture'] as String? ??
              avatarVal['avatar_url'] as String? ??
              avatarVal['url'] as String? ??
              avatarVal['path'] as String? ??
              avatarVal['file_url'] as String?;
        }
      } else if (parsed is String) {
        resolvedUrl = parsed;
      }
      
      // Fallback to checking root keys of data
      if (resolvedUrl == null && data is Map) {
        final avatarVal = data['profile_picture'] ?? data['avatar_url'] ?? data['avatar'] ?? data['url'] ?? data['file_url'] ?? data['path'];
        if (avatarVal is String) {
          resolvedUrl = avatarVal;
        } else if (avatarVal is Map) {
          resolvedUrl = avatarVal['profile_picture'] as String? ??
              avatarVal['avatar_url'] as String? ??
              avatarVal['url'] as String? ??
              avatarVal['path'] as String? ??
              avatarVal['file_url'] as String?;
        }
      }
      
      // Prepend base URL if relative path
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        if (resolvedUrl.startsWith('http')) {
          if (resolvedUrl.contains('/profile_pictures/') && !resolvedUrl.contains('/storage/profile_pictures/')) {
            resolvedUrl = resolvedUrl.replaceFirst('/profile_pictures/', '/storage/profile_pictures/');
          }
        } else {
          if (resolvedUrl.startsWith('profile_pictures') && !resolvedUrl.startsWith('storage/')) {
            resolvedUrl = 'storage/$resolvedUrl';
          }
          final baseUrlClean = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
          final pathClean = resolvedUrl.startsWith('/') ? resolvedUrl : '/$resolvedUrl';
          resolvedUrl = '$baseUrlClean$pathClean';
        }
      }
      
      return resolvedUrl ?? '';
    } else {
      throw Exception('Failed to upload picture: ${response.statusCode} ${response.body}');
    }
  }

  // 4. DELETE /api/profile/picture
  Future<void> deleteProfilePicture() async {
    final url = Uri.parse('$_baseUrl/api/profile/picture');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete picture: ${response.statusCode} ${response.body}');
    }
  }

  // 5. PUT /api/profile/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/api/profile/change-password');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
        'old_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      }),
    ).timeout(const Duration(seconds: 300));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      final errorMsg = data is Map ? (data['message'] ?? data['error'] ?? response.body) : response.body;
      throw Exception(errorMsg);
    }
  }

  // 6. GET /api/portfolio
  Future<List<PortfolioItem>> fetchPortfolio() async {
    final url = Uri.parse('$_baseUrl/api/portfolio');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final itemsJson = data is Map && data.containsKey('data') ? data['data'] : data;
      if (itemsJson is List) {
        return itemsJson.map((item) => PortfolioItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to fetch portfolio: ${response.statusCode} ${response.body}');
    }
  }

  // 7. POST /api/portfolio
  Future<PortfolioItem> addPortfolioItem(PortfolioItem item, Uint8List bytes) async {
    final url = Uri.parse('$_baseUrl/api/portfolio');
    final headers = await AuthService.getAuthHeaders();
    
    final request = http.MultipartRequest('POST', url);
    headers.forEach((key, value) {
      request.headers[key] = value;
    });

    request.fields['title'] = item.title;
    request.fields['type'] = item.type.name;

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: item.title,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final itemJson = data is Map && data.containsKey('data') ? data['data'] : data;
      return PortfolioItem.fromJson(itemJson as Map<String, dynamic>);
    } else {
      throw Exception('Failed to add portfolio item: ${response.statusCode} ${response.body}');
    }
  }

  // 8. GET /api/portfolio/{id}
  Future<PortfolioItem> fetchPortfolioItem(String id) async {
    final url = Uri.parse('$_baseUrl/api/portfolio/$id');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final itemJson = data is Map && data.containsKey('data') ? data['data'] : data;
      return PortfolioItem.fromJson(itemJson as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch portfolio item: ${response.statusCode} ${response.body}');
    }
  }

  // 9. PUT /api/portfolio/{id}
  Future<PortfolioItem> updatePortfolioItem(String id, PortfolioItem item) async {
    final url = Uri.parse('$_baseUrl/api/portfolio/$id');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'title': item.title,
        'type': item.type.name,
      }),
    ).timeout(const Duration(seconds: 300));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final itemJson = data is Map && data.containsKey('data') ? data['data'] : data;
      return PortfolioItem.fromJson(itemJson as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update portfolio item: ${response.statusCode} ${response.body}');
    }
  }

  // 10. DELETE /api/portfolio/{id}
  Future<void> deletePortfolioItem(String id) async {
    final url = Uri.parse('$_baseUrl/api/portfolio/$id');
    final headers = await AuthService.getAuthHeaders();
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 300));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete portfolio item: ${response.statusCode} ${response.body}');
    }
  }
}
