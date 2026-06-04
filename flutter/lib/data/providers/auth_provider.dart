import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class AuthProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> register({
    String? username,
    String? email,
    String? phone,
    required String password,
    String? nickname,
  }) async {
    final response = await _api.dio.post(ApiEndpoints.register, data: {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
      if (nickname != null) 'nickname': nickname,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String account,
    required String password,
  }) async {
    final response = await _api.dio.post(ApiEndpoints.login, data: {
      'account': account,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> loginBySms({
    required String phone,
    required String code,
  }) async {
    final response = await _api.dio.post(ApiEndpoints.loginSms, data: {
      'phone': phone,
      'code': code,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    final response = await _api.dio.post(ApiEndpoints.sendSms, data: {
      'phone': phone,
    });
    return response.data;
  }
}
