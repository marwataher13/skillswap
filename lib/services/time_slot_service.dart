import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/services/auth_service.dart';

class TimeSlotService {
  static const String _base = '${AppConfig.baseUrl}/api/time-slots';

  // ─── GET /api/time-slots ───────────────────────────────────────
  Future<List<TimeSlotModel>> getMyTimeSlots() async {
    debugPrint('TimeSlotService: Fetching time slots...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse(_base), headers: headers)
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Fetching time slots response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Fetching time slots response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['timeslots'] ??
              decoded['time_slots'] ??
              decoded['data'] ??
              [])
        : (decoded is List ? decoded : []);

    final list = raw
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort by day order
    list.sort(
      (a, b) => TimeSlotModel.dayOrder(
        a.dayOfWeek,
      ).compareTo(TimeSlotModel.dayOrder(b.dayOfWeek)),
    );

    return list;
  }

  // ─── POST /api/time-slots ──────────────────────────────────────
  Future<TimeSlotModel> createTimeSlot({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    debugPrint('TimeSlotService: Creating time slot...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .post(
          Uri.parse(_base),
          headers: headers,
          body: jsonEncode({
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Creating time slot response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Creating time slot response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final slotJson = decoded is Map
        ? (decoded['timeslot'] ??
              decoded['time_slot'] ??
              decoded['data'] ??
              decoded)
        : decoded;

    return TimeSlotModel.fromJson(slotJson as Map<String, dynamic>);
  }

  // ─── PUT /api/time-slots/{id} ──────────────────────────────────
  Future<TimeSlotModel> updateTimeSlot({
    required int id,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    debugPrint('TimeSlotService: Updating time slot $id...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .put(
          Uri.parse('$_base/$id'),
          headers: headers,
          body: jsonEncode({
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
          }),
        )
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Updating time slot response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Updating time slot response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final slotJson = decoded is Map
        ? (decoded['timeslot'] ??
              decoded['time_slot'] ??
              decoded['data'] ??
              decoded)
        : decoded;

    return TimeSlotModel.fromJson(slotJson as Map<String, dynamic>);
  }

  // ─── DELETE /api/time-slots/{id} ───────────────────────────────
  Future<void> deleteTimeSlot(int id) async {
    debugPrint('TimeSlotService: Deleting time slot $id...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .delete(Uri.parse('$_base/$id'), headers: headers)
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Deleting time slot response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Deleting time slot response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response.body, response.statusCode));
    }
  }

  // ─── PATCH /api/time-slots/{id}/toggle ────────────────────────
  Future<TimeSlotModel> toggleAvailability(int id) async {
    debugPrint('TimeSlotService: Toggling availability for slot $id...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .patch(Uri.parse('$_base/$id/toggle'), headers: headers)
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Toggling availability response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Toggling availability response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final slotJson = decoded is Map
        ? (decoded['timeslot'] ??
              decoded['time_slot'] ??
              decoded['data'] ??
              decoded)
        : decoded;

    return TimeSlotModel.fromJson(slotJson as Map<String, dynamic>);
  }

  // ─── GET /api/time-slots/suggest/{userId} ─────────────────────
  Future<List<TimeSlotModel>> suggestMeetingTimes(int userId) async {
    debugPrint('TimeSlotService: Suggesting meeting times for user $userId...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse('$_base/suggest/$userId'), headers: headers)
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Suggesting meeting times response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Suggesting meeting times response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['suggestions'] ??
            decoded['time_slots'] ??
            decoded['timeslots'] ??
            decoded['data'] ??
            [])
        : (decoded is List ? decoded : []);

    return raw
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── GET /api/users/{userId}/time-slots ───────────────────────
  Future<List<TimeSlotModel>> getUserTimeSlots(int userId) async {
    debugPrint('TimeSlotService: Fetching user time slots for user $userId...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/api/users/$userId/time-slots'), headers: headers)
        .timeout(const Duration(seconds: 300));

    debugPrint('TimeSlotService: Fetching user time slots response code: ${response.statusCode}');
    debugPrint('TimeSlotService: Fetching user time slots response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['timeslots'] ??
              decoded['time_slots'] ??
              decoded['data'] ??
              [])
        : (decoded is List ? decoded : []);

    final list = raw
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort by day order
    list.sort(
      (a, b) => TimeSlotModel.dayOrder(
        a.dayOfWeek,
      ).compareTo(TimeSlotModel.dayOrder(b.dayOfWeek)),
    );

    return list;
  }

  // ─── Helpers ───────────────────────────────────────────────────
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
