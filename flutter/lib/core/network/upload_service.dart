import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class UploadService {
  final ApiClient _api = ApiClient();

  Future<String> uploadImage(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _api.dio.post(
      '/upload/image',
      data: formData,
    );
    if (response.data['code'] == 0) {
      final inner = response.data['data'];
      final url = (inner is Map) ? (inner['url'] ?? inner['data']?['url'] ?? '') : '';
      if (url.startsWith('http')) return url;
      return '${AppConstants.baseUrl.replaceAll('/api', '')}$url';
    }
    throw Exception(response.data['message'] ?? 'Upload failed');
  }

  /// Upload from bytes — works on Web and mobile
  Future<String> uploadImageBytes(Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _api.dio.post(
      '/upload/image',
      data: formData,
    );
    if (response.data['code'] == 0) {
      // 后端 TransformInterceptor 包装：{ code, message, data: { code, data: { url } } }
      final inner = response.data['data'];
      final url = (inner is Map) ? (inner['url'] ?? inner['data']?['url'] ?? '') : '';
      if (url.startsWith('http')) return url;
      return '${AppConstants.baseUrl.replaceAll('/api', '')}$url';
    }
    throw Exception(response.data['message'] ?? 'Upload failed');
  }

  /// Upload audio file
  Future<String> uploadAudioBytes(Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType('audio', 'mp4'),
      ),
    });
    final response = await _api.dio.post(
      '/upload/file',
      data: formData,
    );
    if (response.data['code'] == 0) {
      final inner = response.data['data'];
      final url = (inner is Map) ? (inner['url'] ?? inner['data']?['url'] ?? '') : '';
      if (url.startsWith('http')) return url;
      return '${AppConstants.baseUrl.replaceAll('/api', '')}$url';
    }
    throw Exception(response.data['message'] ?? 'Upload failed');
  }
}