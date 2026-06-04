import '../providers/report_provider.dart';

class ReportRepository {
  final ReportProvider _provider = ReportProvider();

  Future<void> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final res = await _provider.createReport({
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      if (description != null) 'description': description,
    });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '举报失败');
    }
  }
}
