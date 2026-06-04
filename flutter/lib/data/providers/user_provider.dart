import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class UserProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.dio.get(ApiEndpoints.userMe);
    return response.data;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _api.dio.patch(ApiEndpoints.userMe, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    final response = await _api.dio.get(ApiEndpoints.userById(id));
    return response.data;
  }
}
