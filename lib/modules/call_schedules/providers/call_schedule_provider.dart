import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import 'models/call_schedule.dart';

class CallScheduleNotifier extends StateNotifier<List<CallSchedule>> {
  final ApiService _api;

  CallScheduleNotifier(this._api) : super([]);

  Future<void> loadSchedules() async {
    try {
      final response = await _api.dio.get('/call-schedules');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? response.data;
        state = (data as List).map((e) => CallSchedule.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  Future<bool> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.post('/call-schedules', data: data);
      if (response.statusCode == 201) {
        final newSchedule = CallSchedule.fromJson(
          response.data['data'] ?? response.data,
        );
        state = [newSchedule, ...state];
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating schedule: $e');
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      final response = await _api.dio.patch(
        '/call-schedules/$id/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        final updated = CallSchedule.fromJson(
          response.data['data'] ?? response.data,
        );
        state = state.map((s) => s.id == id ? updated : s).toList();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(int id) async {
    try {
      final response = await _api.dio.delete('/call-schedules/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.where((s) => s.id != id).toList();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  List<CallSchedule> getForDate(DateTime date) {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    return state.where((s) => s.scheduledDate == formatted).toList();
  }
}

final callScheduleProvider =
    StateNotifierProvider.family<
      CallScheduleNotifier,
      List<CallSchedule>,
      ApiService
    >((ref, api) => CallScheduleNotifier(api));
