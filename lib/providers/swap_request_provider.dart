import 'package:flutter/foundation.dart';
import '../models/swap_request_model.dart';
import '../services/swap_request_service.dart';
import '../utils/exception_utils.dart';

class SwapRequestProvider extends ChangeNotifier {
  final SwapRequestService _service = SwapRequestService();

  List<SwapRequest> _sent = [];
  List<SwapRequest> _received = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  List<SwapRequest> get sent => _sent;
  List<SwapRequest> get received => _received;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingReceivedCount =>
      _received.where((r) => r.status == 'pending').length;

  // ── Load all ──────────────────────────────────────────────────────────────

  Future<void> loadAll({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetchAll();
      _sent = result.sentRequests;
      _received = result.receivedRequests;
      _error = null;
    } catch (e) {
      if (!silent) {
        _error = stripException(e.toString());
      }
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // ── Accept / Reject / Cancel ──────────────────────────────────────────────

  Future<String?> accept(int id) =>
      _performAction(() => _service.accept(id), _received);

  Future<String?> reject(int id) =>
      _performAction(() => _service.reject(id), _received);

  Future<String?> cancel(int id) =>
      _performAction(() => _service.cancel(id), _sent);

  /// Executes [action] and updates the matching item in [list] on success.
  /// Returns `null` on success or an error message on failure.
  Future<String?> _performAction(
    Future<SwapRequest> Function() action,
    List<SwapRequest> list,
  ) async {
    try {
      final updated = await action();
      _updateInList(list, updated);
      notifyListeners();
      return null;
    } catch (e) {
      return stripException(e.toString());
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<String?> send({
    required int receiverId,
    required String message,
  }) async {
    try {
      final newRequest =
          await _service.send(receiverId: receiverId, message: message);
      _sent.insert(0, newRequest);
      notifyListeners();
      return null;
    } catch (e) {
      return stripException(e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  SwapRequest? getAcceptedRequestWithUser(int otherUserId) {
    for (final r in _sent) {
      if (r.receiverId == otherUserId && r.status == 'accepted') return r;
    }
    for (final r in _received) {
      if (r.senderId == otherUserId && r.status == 'accepted') return r;
    }
    return null;
  }

  SwapRequest? getRequestById(int id) {
    try {
      return _sent.firstWhere((r) => r.id == id);
    } catch (_) {}
    try {
      return _received.firstWhere((r) => r.id == id);
    } catch (_) {}
    return null;
  }

  void _updateInList(List<SwapRequest> list, SwapRequest updated) {
    final index = list.indexWhere((r) => r.id == updated.id);
    if (index != -1) list[index] = updated;
  }
}
