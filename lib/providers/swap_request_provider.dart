import 'package:flutter/foundation.dart';
import '../models/swap_request_model.dart';
import '../services/swap_request_service.dart';
 
class SwapRequestProvider extends ChangeNotifier {
  final SwapRequestService _service = SwapRequestService();
 
  List<SwapRequest> _sent = [];
  List<SwapRequest> _received = [];
  bool _isLoading = false;
  String? _error;
 
  List<SwapRequest> get sent => _sent;
  List<SwapRequest> get received => _received;
  bool get isLoading => _isLoading;
  String? get error => _error;
 
  int get pendingReceivedCount =>
      _received.where((r) => r.status == 'pending').length;
 
  // ── Load all ──────────────────────────────────────────────────────────────
 
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
 
    try {
      final result = await _service.fetchAll();
      _sent = result.sentRequests;
      _received = result.receivedRequests;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  // ── Accept ────────────────────────────────────────────────────────────────
 
  Future<String?> accept(int id) async {
    try {
      final updated = await _service.accept(id);
      _updateInList(_received, updated);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
 
  // ── Reject ────────────────────────────────────────────────────────────────
 
  Future<String?> reject(int id) async {
    try {
      final updated = await _service.reject(id);
      _updateInList(_received, updated);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
 
  // ── Cancel ────────────────────────────────────────────────────────────────
 
  Future<String?> cancel(int id) async {
    try {
      final updated = await _service.cancel(id);
      _updateInList(_sent, updated);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
 
  // ── Send ──────────────────────────────────────────────────────────────────
 
  Future<String?> send({
    required int receiverId,
    required String message,
  }) async {
    try {
      final newRequest = await _service.send(
        receiverId: receiverId,
        message: message,
      );
      _sent.insert(0, newRequest);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
 
  // ── Helpers ───────────────────────────────────────────────────────────────
 
  void _updateInList(List<SwapRequest> list, SwapRequest updated) {
    final index = list.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      list[index] = updated;
    }
  }
}