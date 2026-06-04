import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'transfer_controller.dart';

class TransferPage extends GetView<TransferController> {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('转账'),
        backgroundColor: const Color(0xFF2D2B55),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 收款人信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withOpacity(0.1),
                    backgroundImage: controller.receiverAvatar.value.isNotEmpty
                        ? NetworkImage(controller.receiverAvatar.value)
                        : null,
                    child: controller.receiverAvatar.value.isEmpty
                        ? Icon(Icons.person, color: accentColor)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('收款人', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                        controller.receiverName.value,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 金额输入
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('转账金额', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('¥', style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: accentColor,
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller.amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.grey[300], fontSize: 32),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[200]),
                  Obx(() => Text(
                    '余额 ¥${controller.balance.value.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 转账备注
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller.remarkCtrl,
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: '转账备注（选填）',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  isDense: true,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 确认转账按钮
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.submitTransfer(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('确认转账', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
