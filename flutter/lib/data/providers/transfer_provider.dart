import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class TransferProvider {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> createTransfer({
    required String receiverId,
    required double amount,
    String? remark,
    required String paymentPassword,
    String? conversationId,
    String? idempotencyKey,
  }) async {
    final response = await _api.dio.post(ApiEndpoints.transferCreate, data: {
      'receiverId': receiverId,
      'amount': amount,
      'remark': remark,
      'paymentPassword': paymentPassword,
      'conversationId': conversationId,
      'idempotencyKey': idempotencyKey,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> acceptTransfer(String transferId) async {
    final response = await _api.dio.post(ApiEndpoints.transferAccept(transferId));
    return response.data;
  }

  Future<Map<String, dynamic>> refundTransfer(String transferId) async {
    final response = await _api.dio.post(ApiEndpoints.transferRefund(transferId));
    return response.data;
  }

  Future<Map<String, dynamic>> getTransferDetail(String transferId) async {
    final response = await _api.dio.get(ApiEndpoints.transferDetail(transferId));
    return response.data;
  }

  Future<Map<String, dynamic>> getTransferList({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get(ApiEndpoints.transferList, queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  // Payment Password
  Future<Map<String, dynamic>> getPaymentPasswordStatus() async {
    final response = await _api.dio.get(ApiEndpoints.paymentPasswordStatus);
    return response.data;
  }

  Future<Map<String, dynamic>> setPaymentPassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    final data = <String, dynamic>{
      'newPassword': newPassword,
    };
    if (oldPassword != null && oldPassword.isNotEmpty) {
      data['oldPassword'] = oldPassword;
    }
    final response = await _api.dio.post(ApiEndpoints.paymentPasswordSet, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPaymentPassword(String password) async {
    final response = await _api.dio.post(ApiEndpoints.paymentPasswordVerify, data: {
      'password': password,
    });
    return response.data;
  }
}
