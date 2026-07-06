import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  // NOTE: loadData() is called explicitly after login, not here in the
  // constructor, because no auth token exists yet at provider-creation time.
  NotificationProvider();

  // ── Getters ───────────────────────────────────────────────────────────────

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Fetches notifications and unread count in parallel and updates state.
  /// Throws on error so callers can handle optimistic rollback.
  Future<void> _fetchAll() async {
    final results = await Future.wait([
      _notificationService.fetchNotifications(),
      _notificationService.fetchUnreadCount(),
    ]);
    _notifications = results[0] as List<NotificationModel>;
    _unreadCount = results[1] as int;
    _error = null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Full load with loading indicator — use on screen entry.
  Future<void> loadData() async {
    if (_isFetching) return;
    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fetchAll();
    } catch (e) {
      _error = e.toString();
      debugPrint('NotificationProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Silent refresh without a loading indicator — use for background updates.
  Future<void> refreshData() async {
    if (_isFetching) return;
    _isFetching = true;
    _error = null;
    try {
      await _fetchAll();
    } catch (e) {
      debugPrint('NotificationProvider.refreshData error: $e');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Lightweight count-only refresh — used for home-screen badge.
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _notificationService.fetchUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.refreshUnreadCount error: $e');
    }
  }

  /// Optimistically marks all notifications as read, rolling back on failure.
  Future<void> markAllAsRead() async {
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    _notifications = _notifications
        .map((n) => n.read ? n : n.copyWith(read: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _notificationService.markAllRead();
    } catch (e) {
      debugPrint('NotificationProvider.markAllAsRead error: $e');
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistically marks a single notification as read, rolling back on failure.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].read) return;

    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    _notifications[index] = _notifications[index].copyWith(read: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _notificationService.markAsRead(id);
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistically deletes a notification, rolling back on failure.
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final itemToDelete = _notifications[index];
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldUnreadCount = _unreadCount;

    _notifications.removeAt(index);
    if (!itemToDelete.read && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _notificationService.deleteNotification(id);
    } catch (e) {
      debugPrint('NotificationProvider.deleteNotification error: $e');
      _notifications = oldNotifications;
      _unreadCount = oldUnreadCount;
      notifyListeners();
      rethrow;
    }
  }
}
