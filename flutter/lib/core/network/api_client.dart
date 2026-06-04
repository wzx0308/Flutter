import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio _dio;
  final StorageService _storage = StorageService.to;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      // 不对转账、支付密码等业务接口重试 token 刷新
      final path = error.requestOptions.path;
      final shouldRetry = !path.contains('/transfer') &&
          !path.contains('/payment-password') &&
          !path.contains('/auth/login') &&
          !path.contains('/auth/register');
      if (shouldRetry) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retryResponse = await _dio.fetch(error.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      }
    }
    handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}${ApiEndpoints.refresh}',
        data: {'refreshToken': refreshToken},
      );

      if (response.data['code'] == 0) {
        final data = response.data['data'];
        await _storage.saveToken(data['accessToken']);
        await _storage.saveRefreshToken(data['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;
}
