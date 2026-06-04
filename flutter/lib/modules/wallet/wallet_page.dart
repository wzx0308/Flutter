import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'wallet_controller.dart';

class WalletPage extends GetView<WalletController> {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('my_wallet'.tr),
        backgroundColor: const Color(0xFF2D2B55),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 余额卡片 ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2B55), Color(0xFF4A4580)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D2B55).withOpacity(0.25),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('account_balance'.tr, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  Obx(() => Text(
                        '¥ ${controller.balance.value.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 36.sp, fontWeight: FontWeight.bold),
                      )),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 120.w,
                    height: 36.h,
                    child: ElevatedButton(
                      onPressed: () => _showRechargeSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text('recharge'.tr, style: const TextStyle(color: Color(0xFF2D2B55), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ── 充值选项 ──
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Text('recharge_amount'.tr, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: subTextColor)),
            ),
            SizedBox(height: 12.h),
            _buildRechargeGrid(cardColor, textColor),
            SizedBox(height: 16.h),

            // ── 自定义金额 ──
            _buildCustomAmountInput(cardColor, textColor),
            SizedBox(height: 24.h),

            // ── 交易记录 ──
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Text('transaction_history'.tr, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: subTextColor)),
            ),
            SizedBox(height: 12.h),
            _buildTransactionList(cardColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRechargeGrid(Color cardColor, Color textColor) {
    return Obx(() {
      final amounts = controller.rechargeAmounts;
      final selected = controller.selectedAmount.value;
      final isCustom = controller.isCustomAmount.value;
      final isDark = Get.isDarkMode;
      final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ScreenUtil().screenWidth > 600 ? 4 : 3,
          mainAxisSpacing: 10.w,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.6,
        ),
        itemCount: amounts.length,
        itemBuilder: (_, i) {
          final amount = amounts[i];
          final isSelected = !isCustom && selected == amount;
          return GestureDetector(
            onTap: () => controller.selectAmount(amount),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withOpacity(isDark ? 0.2 : 0.08)
                    : cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey[isDark ? 700 : 200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¥$amount', style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? accentColor : textColor,
                  )),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCustomAmountInput(Color cardColor, Color textColor) {
    return Obx(() {
      final isDark = Get.isDarkMode;
      final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
      final isCustom = controller.isCustomAmount.value;
      final text = controller.customAmountText.value;
      return GestureDetector(
        onTap: () => controller.enableCustomAmount(),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isCustom ? accentColor.withOpacity(0.05) : cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isCustom ? accentColor : Colors.grey[isDark ? 700 : 200]!,
              width: isCustom ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.edit_rounded, color: accentColor, size: 18.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: isCustom
                    ? TextField(
                        controller: controller.customAmountCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: accentColor),
                        decoration: InputDecoration(
                          hintText: 'input_amount'.tr,
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
                          prefixText: '¥ ',
                          prefixStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: accentColor),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (v) => controller.customAmountText.value = v,
                      )
                    : Text('custom_amount'.tr, style: TextStyle(fontSize: 16.sp, color: textColor)),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTransactionList(Color cardColor, Color textColor) {
    return Obx(() {
      if (controller.transactions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48.r, color: Colors.grey[300]),
              SizedBox(height: 12.h),
              Text('no_transactions'.tr, style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8.r, offset: Offset(0, 2.h)),
          ],
        ),
        child: Column(
          children: List.generate(controller.transactions.length, (i) {
            final tx = controller.transactions[i];
            final type = tx['type'] ?? '';
            final status = tx['status'] ?? '';
            final amount = tx['amount'] ?? 0;
            final subject = tx['subject'] ?? '';
            final createdAt = tx['createdAt'] ?? '';

            final isRecharge = type == 'RECHARGE';
            final isPending = status == 'PENDING';
            final isFailed = status == 'FAILED' || status == 'CLOSED';

            String timeStr = '';
            if (createdAt.isNotEmpty) {
              try {
                final dt = DateTime.parse(createdAt);
                timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {
                timeStr = createdAt;
              }
            }

            String statusText = '';
            Color statusColor = Colors.grey;
            if (isPending) { statusText = '待支付'; statusColor = Colors.orange; }
            else if (isFailed) { statusText = '失败'; statusColor = Colors.red; }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: (isRecharge ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          isRecharge ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isRecharge ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject.isNotEmpty ? subject : (isRecharge ? '钱包充值' : '消费'),
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15.sp, color: textColor)),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(timeStr, style: TextStyle(fontSize: 12.sp, color: Colors.grey[400])),
                                if (statusText.isNotEmpty) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(statusText, style: TextStyle(fontSize: 10.sp, color: statusColor)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '¥${amount is num ? amount.toStringAsFixed(2) : amount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: isRecharge && !isPending && !isFailed
                              ? const Color(0xFF4CAF50)
                              : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < controller.transactions.length - 1)
                  Divider(height: 1, indent: 68, color: Colors.grey[Get.isDarkMode ? 800 : 100]),
              ],
            );
          }),
        ),
      );
    });
  }

  void _showRechargeSheet(BuildContext context) {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            SizedBox(height: 20.h),
            Text('confirm_recharge'.tr, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            SizedBox(height: 6.h),
            Text('recharge_tip'.tr, style: TextStyle(color: Colors.grey[500], fontSize: 13.sp)),
            SizedBox(height: 20.h),

            // 充值金额
            Obx(() {
              final payAmount = controller.payAmount;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text('recharge_amount_label'.tr, style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
                    SizedBox(height: 4.h),
                    Text(
                      '¥$payAmount',
                      style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55)),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final amount = controller.payAmount;
                        if (amount <= 0) {
                          Get.snackbar('hint_title'.tr, 'invalid_amount'.tr);
                          return;
                        }
                        Get.back();
                        await controller.recharge();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('confirm_pay'.tr, style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
