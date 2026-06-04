import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skillswap/config/app_config.dart';
import 'package:skillswap/models/time_slot_model.dart';
import 'package:skillswap/services/auth_service.dart';

class TimeSlotService {
  static const String _base = '${AppConfig.baseUrl}/api/timeslots';

  // ─── GET /api/timeslots ───────────────────────────────────────
  Future<List<TimeSlotModel>> getMyTimeSlots() async {
    debugPrint('TimeSlotService: Fetching time slots...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse(_base), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load time slots (${response.statusCode})');
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

  // ─── POST /api/timeslots ──────────────────────────────────────
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
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create time slot (${response.statusCode})');
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

  // ─── PUT /api/timeslots/{id} ──────────────────────────────────
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
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to update time slot (${response.statusCode})');
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

  // ─── DELETE /api/timeslots/{id} ───────────────────────────────
  Future<void> deleteTimeSlot(int id) async {
    debugPrint('TimeSlotService: Deleting time slot $id...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .delete(Uri.parse('$_base/$id'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete time slot (${response.statusCode})');
    }
  }

  // ─── PATCH /api/timeslots/{id}/toggle ────────────────────────
  Future<TimeSlotModel> toggleAvailability(int id) async {
    debugPrint('TimeSlotService: Toggling availability for slot $id...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .patch(Uri.parse('$_base/$id/toggle'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle availability (${response.statusCode})');
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

  // ─── GET /api/timeslots/suggest/{userId} ─────────────────────
  Future<List<TimeSlotModel>> suggestMeetingTimes(int userId) async {
    debugPrint('TimeSlotService: Suggesting meeting times for user $userId...');
    final headers = await AuthService.getAuthHeaders();
    final response = await http
        .get(Uri.parse('$_base/suggest/$userId'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to suggest meeting times (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> raw = decoded is Map
        ? (decoded['suggestions'] ?? decoded['data'] ?? [])
        : (decoded is List ? decoded : []);

    return raw
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
