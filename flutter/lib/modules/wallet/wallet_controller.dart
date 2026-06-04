import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/providers/wallet_provider.dart';

class WalletController extends GetxController {
  final WalletProvider _provider = WalletProvider();

  final balance = 0.0.obs;
  final selectedAmount = 50.obs;
  final customAmountCtrl = TextEditingController();
  final customAmountText = ''.obs;
  final isCustomAmount = false.obs;
  final isLoading = false.obs;
  final isSimulating = false.obs;
  final isPolling = false.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  String? _currentTradeNo;
  Timer? _pollTimer;

  final rechargeAmounts = [10, 30, 50, 100, 200, 500];

  final Map<int, int> bonusRules = {
    100: 10,
    200: 30,
    500: 50,
  };

  int getBonus(int amount) {
    if (bonusRules.containsKey(amount)) {
      return bonusRules[amount]!;
    }
    if (amount >= 100) {
      return (amount * 0.1).toInt();
    }
    return 0;
  }

  int get totalAmount {
    final amount = isCustomAmount.value
        ? (int.tryParse(customAmountText.value) ?? 0)
        : selectedAmount.value;
    return amount + getBonus(amount);
  }

  int get payAmount {
    return isCustomAmount.value
        ? (int.tryParse(customAmountText.value) ?? 0)
        : selectedAmount.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadBalance();
    loadTransactions();
  }

  @override
  void onClose() {
    _stopPolling();
    customAmountCtrl.dispose();
    super.onClose();
  }

  Future<void> loadBalance() async {
    try {
      final res = await _provider.getBalance();
      if (res['code'] == 0) {
        balance.value = (res['data']['balance'] ?? 0).toDouble();
      }
    } catch (_) {}
  }

  Future<void> loadTransactions() async {
    try {
      final res = await _provider.getTransactions();
      print('Transaction response keys: ${res.keys.toList()}');
      print('Transaction code: ${res['code']}');
      print('Transaction data type: ${res['data'].runtimeType}');
      if (res['code'] == 0) {
        final data = res['data'];
        final list = (data is Map) ? (data['list'] as List? ?? []) : (data as List? ?? []);
        print('Transaction list length: ${list.length}');
        transactions.value = list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Transaction load error: $e');
    }
  }

  void selectAmount(int amount) {
    isCustomAmount.value = false;
    selectedAmount.value = amount;
    customAmountCtrl.clear();
    customAmountText.value = '';
  }

  void enableCustomAmount() {
    isCustomAmount.value = true;
  }

  Future<void> recharge() async {
    final amount = payAmount;
    if (amount <= 0) {
      Get.snackbar('提示', '请输入有效金额');
      return;
    }

    isLoading.value = true;
    try {
      final res = await _provider.recharge(amount.toDouble());
      if (res['code'] == 0) {
        final data = res['data'];
        final qrCode = data['qrCode'] as String?;
        final tradeNo = data['tradeNo'] as String?;
        if (qrCode != null && tradeNo != null) {
          _currentTradeNo = tradeNo;
          _showQrCodeDialog(qrCode, amount, tradeNo);
        } else {
          Get.snackbar('提示', '未获取到支付二维码，请稍后重试');
        }
      } else {
        Get.snackbar('充值失败', res['message'] ?? '请稍后重试');
      }
    } catch (e) {
      final msg = e.toString().contains('支付宝下单失败')
          ? e.toString().replaceFirst('Exception: ', '')
          : '网络错误，请稍后重试';
      Get.snackbar('充值失败', msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simulatePaySuccess(String tradeNo) async {
    isSimulating.value = true;
    try {
      final res = await _provider.simulatePay(tradeNo);
      if (res['code'] == 0) {
        Get.back();
        Get.snackbar('充值成功', '余额已到账');
        await loadBalance();
        await loadTransactions();
      } else {
        Get.snackbar('模拟支付失败', res['message'] ?? '请稍后重试');
      }
    } catch (e) {
      Get.snackbar('模拟支付失败', '网络错误');
    } finally {
      isSimulating.value = false;
    }
  }

  void _showQrCodeDialog(String qrCodeUrl, int amount, String tradeNo) {
    _startPolling(tradeNo);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('支付宝扫码充值', textAlign: TextAlign.center),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('请使用支付宝扫描二维码支付 ¥$amount',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: QrImageView(
                  data: qrCodeUrl,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => isPolling.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('等待支付确认...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  : const Text('支付完成后请返回刷新余额',
                      style: TextStyle(fontSize: 12, color: Colors.grey))),
            ],
          ),
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: isSimulating.value
                    ? null
                    : () => simulatePaySuccess(tradeNo),
                child: isSimulating.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('模拟支付成功',
                        style: TextStyle(color: Color(0xFF4CAF50))),
              )),
          TextButton(
            onPressed: () {
              _stopPolling();
              Get.back();
              loadBalance();
              loadTransactions();
            },
            child: const Text('刷新余额'),
          ),
          TextButton(
            onPressed: () {
              _stopPolling();
              Get.back();
            },
            child: const Text('取消'),
          ),
        ],
      ),
    ).then((_) => _stopPolling());
  }

  void _startPolling(String tradeNo) {
    _stopPolling();
    isPolling.value = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await _provider.queryOrder(tradeNo);
        if (res['data']?['paid'] == true || res['paid'] == true) {
          _stopPolling();
          Get.back();
          Get.snackbar('充值成功', '余额已到账');
          await loadBalance();
          await loadTransactions();
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    isPolling.value = false;
  }

}
