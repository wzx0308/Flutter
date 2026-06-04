import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../data/providers/transfer_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../wallet/widgets/payment_password_dialog.dart';

class TransferController extends GetxController {
  final TransferProvider _provider = TransferProvider();

  final receiverId = ''.obs;
  final receiverName = ''.obs;
  final receiverAvatar = ''.obs;
  final balance = 0.0.obs;
  final amountCtrl = TextEditingController();
  final remarkCtrl = TextEditingController();
  final isLoading = false.obs;
  final hasPaymentPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    receiverId.value = Get.arguments?['receiverId'] ?? '';
    receiverName.value = Get.arguments?['receiverName'] ?? '';
    receiverAvatar.value = Get.arguments?['receiverAvatar'] ?? '';
    _loadBalance();
    _checkPaymentPassword();
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    remarkCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadBalance() async {
    try {
      final api = ApiClient();
      final balanceRes = await api.dio.get(ApiEndpoints.walletBalance);
      if (balanceRes.data['code'] == 0) {
        balance.value = (balanceRes.data['data']['balance'] ?? 0).toDouble();
      }
    } catch (_) {}
  }

  Future<void> _checkPaymentPassword() async {
    try {
      final res = await _provider.getPaymentPasswordStatus();
      if (res['code'] == 0) {
        hasPaymentPassword.value = res['data']['hasPassword'] ?? false;
      }
    } catch (_) {}
  }

  Future<void> submitTransfer() async {
    final amountText = amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Get.snackbar('提示', '请输入有效金额');
      return;
    }
    if (amount > balance.value) {
      Get.snackbar('提示', '余额不足');
      return;
    }
    if (amountText.contains('.') && amountText.split('.')[1].length > 2) {
      Get.snackbar('提示', '金额最多保留2位小数');
      return;
    }

    if (!hasPaymentPassword.value) {
      _showSetPasswordFirst();
      return;
    }

    // 弹出支付密码输入框
    final password = await showPaymentPasswordDialog();
    if (password == null) return;

    isLoading.value = true;
    try {
      final idempotencyKey = const Uuid().v4();
      final res = await _provider.createTransfer(
        receiverId: receiverId.value,
        amount: amount,
        remark: remarkCtrl.text.trim().isNotEmpty ? remarkCtrl.text.trim() : null,
        paymentPassword: password,
        idempotencyKey: idempotencyKey,
      );
      if (res['code'] == 0) {
        Get.offNamed('/transfer/success', arguments: {
          'amount': amount,
          'receiverName': receiverName.value,
          'receiverAvatar': receiverAvatar.value,
          'transferId': res['data']['transferId'],
          'conversationId': Get.arguments?['conversationId'] ?? '',
        });
      } else {
        Get.snackbar('转账失败', res['message'] ?? '请稍后重试');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? '网络错误';
      Get.snackbar('转账失败', msg);
    } catch (e) {
      Get.snackbar('转账失败', '网络错误，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSetPasswordFirst() {
    Get.defaultDialog(
      title: '提示',
      middleText: '请先设置支付密码',
      textConfirm: '去设置',
      textCancel: '取消',
      onConfirm: () {
        Get.back();
        Get.toNamed('/wallet/set-password');
      },
    );
  }
}
