import '../../core/network/api_client.dart';

class ReportProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async {
    final response = await _api.dio.post('/reports', data: data);
    return response.data;
  }
}
