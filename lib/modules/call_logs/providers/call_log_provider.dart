import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../models/call_log.dart';

final callLogProvider = StateNotifierProvider.family<CallLogNotifier, CallLogState, ApiService>(
  (ref, apiService) => CallLogNotifier(apiService),
);

class CallLogState {
  final List<CallLog> logs;
  final bool isLoading;
  final bool isCreating;
  final bool isDeleting;
  final String? error;

  CallLogState({
    this.logs = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isDeleting = false,
    this.error,
  });

  CallLogState loading() => CallLogState(isLoading: true, error: null);
  CallLogState creating() => CallLogState(isCreating: true, error: null);
  CallLogState deleting() => CallLogState(isDeleting: true, error: null);
  CallLogState loaded(this.logs, {this.error}) => CallLogState(logs: logs, error: error);
  CallLogState errorState(this.error) => CallLogState(error: error);
  CallLogState get clearError => CallLogState(error: null, logs: logs, isLoading: isLoading, isCreating: isCreating, isDeleting: isDeleting);
}

class CallLogNotifier extends StateNotifier<CallLogState> {
  final ApiService _api;

  CallLogNotifier(this._api) : super(CallLogState());

  Future<void> loadCallLogs() async {
    state = state.loading();
    try {
      final response = await _api.dio.get('/call-logs');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      final logs = data.map((json) => CallLog.fromJson(json as Map<String, dynamic>)).toList();
      state = CallLogState.loaded(logs);
    } catch (e) {
      state = CallLogState.errorState(e.toString());
    }
  }

  Future<bool> createCallLog(Map<String, dynamic> data) async {
    state = state.creating();
    try {
      await _api.dio.post('/call-logs', data: data);
      await loadCallLogs();
      return true;
    } catch (e) {
      state = CallLogState(logs: state.logs, isCreating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCallLog(int id) async {
    final currentLogs = state.logs;
    state = CallLogState(isDeleting: true, logs: currentLogs, error: null);
    try {
      await _api.dio.delete('/call-logs/$id');
      state = CallLogState(logs: currentLogs.where((log) => log.id != id).toList(), isDeleting: false);
      return true;
    } catch (e) {
      state = CallLogState(isDeleting: false, logs: currentLogs, error: e.toString());
      return false;
    }
  }
}
