import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/admin_provider.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _provider = AdminProvider();
  final _reports = <dynamic>[].obs;
  final _isLoading = false.obs;
  int _page = 1;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({int page = 1, String? status}) async {
    _isLoading.value = true;
    _statusFilter = status;
    try {
      final res = await _provider.getReports(page: page, status: status);
      if (res['code'] == 0) {
        _reports.value = res['data']['reports'] ?? [];
        _page = page;
      }
    } catch (_) {} finally {
      _isLoading.value = false;
    }
  }

  Future<void> _updateStatus(String reportId, String status) async {
    try {
      await _provider.updateReportStatus(reportId, status);
      Get.snackbar('success'.tr, 'report_status_updated'.tr);
      _loadReports(page: _page, status: _statusFilter);
    } catch (e) {
      Get.snackbar('failed'.tr, e.toString());
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'SPAM': return 'report_spam'.tr;
      case 'ABUSE': return 'report_abuse'.tr;
      case 'ILLEGAL': return 'report_illegal'.tr;
      case 'OTHER': return 'report_other'.tr;
      default: return reason;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'pending'.tr;
      case 'REVIEWED': return 'reviewed'.tr;
      case 'RESOLVED': return 'resolved'.tr;
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'REVIEWED': return Colors.blue;
      case 'RESOLVED': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('report_management'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _filterChip('all'.tr, null, isDark),
                const SizedBox(width: 8),
                _filterChip('pending'.tr, 'PENDING', isDark),
                const SizedBox(width: 8),
                _filterChip('reviewed'.tr, 'REVIEWED', isDark),
                const SizedBox(width: 8),
                _filterChip('resolved'.tr, 'RESOLVED', isDark),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_isLoading.value) return const Center(child: CircularProgressIndicator());
              if (_reports.isEmpty) return Center(child: Text('no_data'.tr));
              return ListView.separated(
                itemCount: _reports.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                itemBuilder: (_, i) {
                  final report = _reports[i];
                  return Material(
                    color: cardColor,
                    child: ListTile(
                      leading: Icon(
                        report['targetType'] == 'POST' ? Icons.article : (report['targetType'] == 'USER' ? Icons.person : Icons.comment),
                        color: _statusColor(report['status']),
                      ),
                      title: Text(_reasonLabel(report['reason']), style: TextStyle(color: textColor)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${'type_label'.tr}: ${report['targetType']} | ${'target_label'.tr}: ${report['targetId']?.substring(0, 8)}...', style: TextStyle(color: Colors.grey[400])),
                          if (report['description'] != null) Text(report['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(report['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_statusLabel(report['status']), style: TextStyle(color: _statusColor(report['status']), fontSize: 12)),
                          ),
                          if (report['status'] == 'PENDING')
                            PopupMenuButton<String>(
                              onSelected: (v) => _updateStatus(report['id'], v),
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'REVIEWED', child: Text('mark_reviewed'.tr)),
                                PopupMenuItem(value: 'RESOLVED', child: Text('mark_resolved'.tr)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status, bool isDark) {
    final selected = _statusFilter == status;
    return GestureDetector(
      onTap: () => _loadReports(status: status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.red : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
