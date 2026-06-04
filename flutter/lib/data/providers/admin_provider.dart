import '../../core/network/api_client.dart';

class AdminProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _api.dio.get('/admin/dashboard');
    return response.data;
  }

  Future<Map<String, dynamic>> getUsers({int page = 1, String? keyword, String? status}) async {
    final response = await _api.dio.get('/admin/users', queryParameters: {
      'page': page,
      if (keyword != null) 'keyword': keyword,
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateUserStatus(String userId, String status) async {
    final response = await _api.dio.patch('/admin/users/$userId/status', data: {'status': status});
    return response.data;
  }

  Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    final response = await _api.dio.patch('/admin/users/$userId/role', data: {'role': role});
    return response.data;
  }

  Future<Map<String, dynamic>> getPosts({int page = 1, String? status, String? keyword}) async {
    final response = await _api.dio.get('/admin/posts', queryParameters: {
      'page': page,
      if (status != null) 'status': status,
      if (keyword != null) 'keyword': keyword,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updatePostStatus(String postId, String status) async {
    final response = await _api.dio.patch('/admin/posts/$postId/status', data: {'status': status});
    return response.data;
  }

  Future<Map<String, dynamic>> getReports({int page = 1, String? status}) async {
    final response = await _api.dio.get('/admin/reports', queryParameters: {
      'page': page,
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateReportStatus(String reportId, String status) async {
    final response = await _api.dio.patch('/admin/reports/$reportId/status', data: {'status': status});
    return response.data;
  }
}
