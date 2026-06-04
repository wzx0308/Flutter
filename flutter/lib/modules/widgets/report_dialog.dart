import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/report_repository.dart';

class ReportDialog extends StatelessWidget {
  final String targetType;
  final String targetId;
  final _repo = ReportRepository();

  ReportDialog({super.key, required this.targetType, required this.targetId});

  static void show(BuildContext context, {required String targetType, required String targetId}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReportDialog(targetType: targetType, targetId: targetId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasons = [
      {'value': 'SPAM', 'label': '垃圾广告', 'icon': Icons.block},
      {'value': 'ABUSE', 'label': '辱骂骚扰', 'icon': Icons.warning},
      {'value': 'ILLEGAL', 'label': '违法违规', 'icon': Icons.gavel},
      {'value': 'OTHER', 'label': '其他原因', 'icon': Icons.more_horiz},
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('举报', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ...reasons.map((r) => ListTile(
                leading: Icon(r['icon'] as IconData, color: Colors.grey),
                title: Text(r['label'] as String),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _submit(r['value'] as String);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _submit(String reason) async {
    try {
      await _repo.createReport(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
      Get.snackbar('成功', '举报已提交，我们会尽快处理',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('失败', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
