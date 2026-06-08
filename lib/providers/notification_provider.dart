import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationProvider() {
    // Automatically load data on startup/provider registration
    loadData();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Fetches the full notifications list and the current unread count.
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _notificationService.fetchNotifications(),
        _notificationService.fetchUnreadCount(),
      ]);

      _notifications = results[0] as List<NotificationModel>;
      _unreadCount = results[1] as int;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('NotificationProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes data without showing a full-screen loading spinner (subtle update)
  Future<void> refreshData() async {
    _error = null;
    try {
      final results = await Future.wait([
        _notificationService.fetchNotifications(),
        _notificationService.fetchUnreadCount(),
      ]);

      _notifications = results[0] as List<NotificationModel>;
      _unreadCount = results[1] as int;
      _error = null;
    } catch (e) {
      debugPrint('NotificationProvider.refreshData error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    // Optimistic Update
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    _notifications = _notifications.map((item) {
      if (!item.read) {
        return NotificationModel(
          id: item.id,
          title: item.title,
          message: item.message,
          type: item.type,
          read: true,
          createdAt: item.createdAt,
        );
      }
      return item;
    }).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _notificationService.markAllRead();
    } catch (e) {
      debugPrint('NotificationProvider.markAllAsRead error: $e');
      // Rollback on failure
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  /// Mark a specific notification as read.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1 || _notifications[index].read) return;

    // Optimistic Update
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    final updatedItem = NotificationModel(
      id: _notifications[index].id,
      title: _notifications[index].title,
      message: _notifications[index].message,
      type: _notifications[index].type,
      read: true,
      createdAt: _notifications[index].createdAt,
    );

    _notifications[index] = updatedItem;
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _notificationService.markAsRead(id);
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
      // Rollback on failure
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final itemToDelete = _notifications[index];

    // Optimistic Update
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    _notifications.removeAt(index);
    if (!itemToDelete.read && _unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('NotificationProvider.deleteNotification error: $e');
      // Rollback on failure
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }
}
