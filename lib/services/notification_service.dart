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

    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    debugPrint('NotificationService: fetchNotifications status = ${response.statusCode}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 1. Bare list: [...]
      if (decoded is List) {
        return decoded
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        // 2. Flat wrapper — list directly under a known key
        //    e.g. { "data": [...] }  or  { "notifications": [...] }
        for (final key in ['data', 'notifications', 'results', 'items', 'records']) {
          final val = decoded[key];
          if (val is List) {
            return val
                .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }

        // 3. Paginated wrapper under any top-level key:
        //    ACTUAL SHAPE: { "message": "...", "notifications": { "current_page": 1, "data": [...] } }
        //    Also handles: { "data": { "current_page": 1, "data": [...] } }
        for (final outerKey in ['notifications', 'data', 'results', 'items']) {
          final inner = decoded[outerKey];
          if (inner is Map<String, dynamic>) {
            for (final innerKey in ['data', 'items', 'results', 'notifications']) {
              final val = inner[innerKey];
              if (val is List) {
                return val
                    .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
                    .toList();
              }
            }
          }
        }
      }

      // Unknown shape — throw so the error state shows instead of a silent blank screen
      throw Exception(
        'Unexpected notifications response shape: '
        '${response.body.substring(0, response.body.length.clamp(0, 300))}',
      );
    } else {
      throw Exception('Failed to fetch notifications: ${response.statusCode} ${response.body}');
    }
  }

  /// Get the count of unread notifications.
  Future<int> fetchUnreadCount() async {
    final url = Uri.parse('$_baseUrl/api/notifications/unread-count');
    final headers = await AuthService.getAuthHeaders();

    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 300));

    debugPrint('NotificationService: fetchUnreadCount status = ${response.statusCode}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is num) {
        return decoded.toInt();
      }

      if (decoded is Map) {
        final countValue = decoded['unread_count'] ??
            decoded['unreadCount'] ??
            decoded['count'] ??
            decoded['unread'] ??
            0;
        if (countValue is num) {
          return countValue.toInt();
        } else if (countValue is String) {
          return int.tryParse(countValue) ?? 0;
        }
      }

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

    final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 300));

    debugPrint('NotificationService: markAllRead status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
      throw Exception('Failed to mark all as read: ${response.statusCode} ${response.body}');
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    final url = Uri.parse('$_baseUrl/api/notifications/$id/read');
    final headers = await AuthService.getAuthHeaders();

    final response = await http.put(url, headers: headers).timeout(const Duration(seconds: 300));

    debugPrint('NotificationService: markAsRead status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark notification as read: ${response.statusCode} ${response.body}');
    }
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String id) async {
    final url = Uri.parse('$_baseUrl/api/notifications/$id');
    final headers = await AuthService.getAuthHeaders();

    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 300));

    debugPrint('NotificationService: deleteNotification status = ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification: ${response.statusCode} ${response.body}');
    }
  }
}