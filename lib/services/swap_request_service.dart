import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/swap_request_model.dart';
 
class SwapRequestsResult {
  final List<SwapRequest> sentRequests;
  final List<SwapRequest> receivedRequests;
 
  const SwapRequestsResult({
    required this.sentRequests,
    required this.receivedRequests,
  });
}
 
class SwapRequestService {
  static const String _base = '${AppConfig.baseUrl}/api/swap-requests';
 
  // ── GET ALL ───────────────────────────────────────────────────────────────
 
  Future<SwapRequestsResult> fetchAll() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(Uri.parse(_base), headers: headers);
 
    debugPrint('SwapRequestService.fetchAll: ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final sent = (data['sent_requests'] as List<dynamic>? ?? [])
          .map((e) => SwapRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      final received = (data['received_requests'] as List<dynamic>? ?? [])
          .map((e) => SwapRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      return SwapRequestsResult(sentRequests: sent, receivedRequests: received);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── GET SINGLE ────────────────────────────────────────────────────────────
 
  Future<SwapRequest> fetchById(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response =
        await http.get(Uri.parse('$_base/$id'), headers: headers);
 
    debugPrint('SwapRequestService.fetchById($id): ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SwapRequest.fromJson(
          data['swap_request'] as Map<String, dynamic>);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── SEND ──────────────────────────────────────────────────────────────────
 
  Future<SwapRequest> send({
    required int receiverId,
    required String message,
  }) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.post(
      Uri.parse(_base),
      headers: headers,
      body: jsonEncode({'receiver_id': receiverId, 'message': message}),
    );
 
    debugPrint('SwapRequestService.send: ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SwapRequest.fromJson(
          data['swap_request'] as Map<String, dynamic>);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── ACCEPT ────────────────────────────────────────────────────────────────
 
  Future<SwapRequest> accept(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$_base/$id/accept'),
      headers: headers,
    );
 
    debugPrint('SwapRequestService.accept($id): ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SwapRequest.fromJson(
          data['swap_request'] as Map<String, dynamic>);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── REJECT ────────────────────────────────────────────────────────────────
 
  Future<SwapRequest> reject(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$_base/$id/reject'),
      headers: headers,
    );
 
    debugPrint('SwapRequestService.reject($id): ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SwapRequest.fromJson(
          data['swap_request'] as Map<String, dynamic>);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── CANCEL ────────────────────────────────────────────────────────────────
 
  Future<SwapRequest> cancel(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$_base/$id/cancel'),
      headers: headers,
    );
 
    debugPrint('SwapRequestService.cancel($id): ${response.statusCode}');
 
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SwapRequest.fromJson(
          data['swap_request'] as Map<String, dynamic>);
    }
 
    throw Exception(_extractError(response.body, response.statusCode));
  }
 
  // ── Helpers ───────────────────────────────────────────────────────────────
 
  String _extractError(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        if (data.containsKey('message')) return data['message'].toString();
        if (data.containsKey('error')) return data['error'].toString();
      }
    } catch (_) {}
    return 'Server error ($statusCode)';
  }
}