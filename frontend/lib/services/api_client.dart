import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  dio.interceptors.add(_AuthInterceptor(ref, dio));
  dio.interceptors.add(_ErrorInterceptor());
  return dio;
}

// ---------------------------------------------------------------------------
// Auth interceptor — attaches Bearer token and handles 401 refresh
// ---------------------------------------------------------------------------

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  _AuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _ref.read(authProvider).whenOrNull(
      authenticated: (_, token) {
        options.headers['Authorization'] = 'Bearer $token';
      },
    );
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final newToken = await _ref.read(authProvider.notifier).refreshToken();
    if (newToken == null) {
      // Refresh failed — propagate the error; router will redirect to /login.
      handler.next(err);
      return;
    }

    // Retry original request with new access token.
    try {
      final retried = await _dio.fetch<dynamic>(
        err.requestOptions..headers['Authorization'] = 'Bearer $newToken',
      );
      handler.resolve(retried);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }
}

// ---------------------------------------------------------------------------
// Error interceptor — maps non-2xx to typed ApiException
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.detail});

  final int statusCode;
  final String detail;

  @override
  String toString() => 'ApiException($statusCode): $detail';
}

class _ErrorInterceptor extends InterceptorsWrapper {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response == null) {
      handler.next(err);
      return;
    }

    // Django Ninja returns {"detail": "..."} for errors.
    final data = response.data;
    String detail = 'An unexpected error occurred.';
    if (data is Map<String, dynamic>) {
      detail = data['detail']?.toString() ?? detail;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: ApiException(statusCode: response.statusCode!, detail: detail),
        type: err.type,
      ),
    );
  }
}
