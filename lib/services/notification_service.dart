import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static const String _baseUrl = AppConfig.baseUrl;

  /// Fetch list of notifications from the server.
  Future<List<NotificationModel>> fetchNotifications() async {
    final url = Uri.parse('$_baseUrl/api/notifications');
    final headers = await AuthService.getAuthHeaders();
    
    debugPrint('NotificationService: GET $url');
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    debugPrint('NotificationService: fetchNotifications status = ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      // Handle list directly
      if (decoded is List) {
        return decoded.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      
      // Handle map wrapper
      if (decoded is Map) {
        final data = decoded['data'] ?? decoded['notifications'] ?? decoded['results'];
        if (data is List) {
          return data.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      
      return [];
    } else {
      throw Exception('Failed to fetch notifications: ${response.statusCode} ${response.body}');
    }
  }

  /// Get the count of unread notifications.
  Future<int> fetchUnreadCount() async {
    final url = Uri.parse('$_baseUrl/api/notifications/unread-count');
    final headers = await AuthService.getAuthHeaders();
    
    debugPrint('NotificationService: GET $url');
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    debugPrint('NotificationService: fetchUnreadCount status = ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      if (decoded is num) {
        return decoded.toInt();
      }
      
      if (decoded is Map) {
        final countValue = decoded['unread_count'] ?? decoded['unreadCount'] ?? decoded['count'] ?? decoded['unread'] ?? 0;
        if (countValue is num) {
          return countValue.toInt();
        } else if (countValue is String) {
          return int.tryParse(countValue) ?? 0;
        }
      }
      
      // If we could not extract, try parsing body directly as an int
      final parsedDirect = int.tryParse(response.body.trim());
      if (parsedDirect != null) {
        return parsedDirect;
      }
      
      return 0;
    } else {
      throw Exception('Failed to fetch unread count: ${response.statusCode} ${response.body}');
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    final url = Uri.parse('$_baseUrl/api/notifications/mark-all-read');
    final headers = await AuthService.getAuthHeaders();
    
    debugPrint('NotificationService: POST $url');
    final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 15));

    debugPrint('NotificationService: markAllRead status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
      throw Exception('Failed to mark all as read: ${response.statusCode} ${response.body}');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    final url = Uri.parse('$_baseUrl/api/notifications/$id/read');
    final headers = await AuthService.getAuthHeaders();
    
    debugPrint('NotificationService: PUT $url');
    final response = await http.put(url, headers: headers).timeout(const Duration(seconds: 15));

    debugPrint('NotificationService: markAsRead status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark notification as read: ${response.statusCode} ${response.body}');
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String id) async {
    final url = Uri.parse('$_baseUrl/api/notifications/$id');
    final headers = await AuthService.getAuthHeaders();
    
    debugPrint('NotificationService: DELETE $url');
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));

    debugPrint('NotificationService: deleteNotification status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification: ${response.statusCode} ${response.body}');
    }
  }
}
