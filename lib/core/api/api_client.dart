import 'package:dio/dio.dart';

import '../constants.dart';
import 'api_envelope.dart';
import 'api_failure.dart';
import 'token_store.dart';

/// The single way this app talks to the CRM.
///
/// Every response — success or failure — arrives in the same envelope, so
/// this class decodes once and hands the rest of the app either an
/// [ApiEnvelope] or an [ApiFailure]. No screen ever sees a [DioException] or
/// an HTTP status code.
class ApiClient {
  ApiClient({required this._tokens, Dio? dio, this.onSignOut})
      : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConstants.baseUrl
      ..connectTimeout = AppConstants.connectTimeout
      ..receiveTimeout = AppConstants.receiveTimeout
      ..headers.addAll({'Accept': 'application/json'})
      // Take every status: the body is the envelope either way, and letting
      // Dio throw on 4xx would mean decoding failures in two places.
      ..validateStatus = (_) => true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokens;

  /// Called when the server says this token is finished — expired, the
  /// account switched off, or the role moved. The app drops to login.
  final void Function(ApiFailure failure)? onSignOut;

  Future<ApiEnvelope> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<ApiEnvelope> post(String path, {Object? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<ApiEnvelope> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<ApiEnvelope> _send(Future<Response<dynamic>> Function() run) async {
    final Response<dynamic> response;

    try {
      response = await run();
    } on DioException catch (e) {
      // Only a genuine transport problem is a network problem. Anything
      // else — most often Dio failing to decode a body that claimed to be
      // JSON — means we did reach the server, and telling the rep to check
      // their signal would send them chasing the wrong thing.
      throw switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          const ApiFailure(
            reason: ApiReason.network,
            message: 'The server took too long to answer. Try again.',
          ),
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate =>
          const ApiFailure(
            reason: ApiReason.network,
            message: 'Cannot reach the server. Check your connection.',
          ),
        _ => ApiFailure(
            reason: ApiReason.serverError,
            message: 'The server sent something this app could not read.',
            status: e.response?.statusCode,
          ),
      };
    }

    final body = response.data;

    if (body is! Map) {
      // Not our envelope: a proxy error page, or HTML from a wrong base URL.
      throw ApiFailure(
        reason: ApiReason.serverError,
        message: 'The server sent something this app could not read.',
        status: response.statusCode,
      );
    }

    final envelope = ApiEnvelope.fromJson(body.cast<String, dynamic>());

    if (envelope.success) {
      return envelope;
    }

    final failure = _failure(envelope, response);

    if (failure.requiresSignOut) {
      onSignOut?.call(failure);
    }

    throw failure;
  }

  ApiFailure _failure(ApiEnvelope envelope, Response<dynamic> response) {
    final errors = envelope.errors ?? const <String, dynamic>{};

    // Everything beside `reason` is a field name with a list of messages.
    final fields = <String, List<String>>{};
    for (final entry in errors.entries) {
      if (entry.key == 'reason') continue;
      final value = entry.value;
      if (value is List) {
        fields[entry.key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        fields[entry.key] = [value];
      }
    }

    return ApiFailure(
      reason: ApiReason.parse(errors['reason'] as String?),
      message: envelope.message ?? 'Something went wrong.',
      status: response.statusCode,
      fieldErrors: fields,
      retryAfter: _retryAfter(response),
    );
  }

  Duration? _retryAfter(Response<dynamic> response) {
    final raw = response.headers.value('retry-after');
    final seconds = int.tryParse(raw ?? '');

    return seconds == null ? null : Duration(seconds: seconds);
  }
}
