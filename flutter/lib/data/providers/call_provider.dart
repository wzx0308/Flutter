import '../../core/network/api_client.dart';

class CallProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getToken(String channelName) async {
    final res = await _api.dio.get(
      '/calls/token',
      queryParameters: {'channelName': channelName},
    );
    return res.data['data'] ?? res.data;
  }

  Future<Map<String, dynamic>> getCallHistory({int page = 1, int limit = 20}) async {
    final res = await _api.dio.get(
      '/calls/history',
      queryParameters: {'page': page, 'limit': limit},
    );
    return res.data['data'] ?? res.data;
  }
}
