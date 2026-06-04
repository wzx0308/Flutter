import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class WalletProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _api.dio.get(ApiEndpoints.walletBalance);
    return response.data;
  }

  Future<Map<String, dynamic>> recharge(double amount) async {
    final response = await _api.dio.post(ApiEndpoints.walletRecharge, data: {
      'amount': amount,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> simulatePay(String tradeNo) async {
    final response = await _api.dio.post('/wallet/simulate-pay/$tradeNo');
    return response.data;
  }

  Future<Map<String, dynamic>> queryOrder(String tradeNo) async {
    final response = await _api.dio.get('/wallet/query-order/$tradeNo');
    return response.data;
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get(ApiEndpoints.walletTransactions, queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }
}
