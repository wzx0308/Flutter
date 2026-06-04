import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/storage_service.dart';
import '../models/rag_document_model.dart';

class AiChatProvider {
  late final Dio _dio;

  AiChatProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ));
    // 添加 JWT 鉴权拦截器 + token 自动刷新
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.to.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // FormData 请求由 Dio 自动设置 multipart boundary，不要覆盖
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final retryResponse = await _dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = StorageService.to.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}${ApiEndpoints.refresh}',
        data: {'refreshToken': refreshToken},
      );

      if (response.data['code'] == 0) {
        final data = response.data['data'];
        await StorageService.to.saveToken(data['accessToken']);
        await StorageService.to.saveRefreshToken(data['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 流式对话补全 - 通过后端代理（SSE）
  Future<Stream<String>> streamChatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required bool deepThinking,
    CancelToken? cancelToken,
    String? mode,
    String? conversationId,
  }) async {
    final response = await _dio.post(
      '/ai-proxy/chat/completions/stream',
      data: {
        'model': model,
        'messages': messages,
        'stream': true,
        if (mode != null) 'mode': mode,
        if (conversationId != null) 'conversationId': conversationId,
        if (deepThinking) ...{
          'enable_thinking': true,
          'thinking_budget': 5120,
        },
      },
      options: Options(responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );

    return response.data.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && line != 'data: [DONE]')
        .map((line) {
      try {
        final jsonStr = line.substring(6);
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final delta = json['choices']?[0]?['delta']?['content'] ?? '';
        return delta as String;
      } catch (_) {
        return '';
      }
    }).where((token) => token.isNotEmpty);
  }

  /// 非流式对话补全 - 通过后端代理
  Future<String> chatCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required bool deepThinking,
    String? mode,
    String? conversationId,
  }) async {
    final response = await _dio.post('/ai-proxy/chat/completions', data: {
      'model': model,
      'messages': messages,
      'stream': false,
      if (mode != null) 'mode': mode,
      if (conversationId != null) 'conversationId': conversationId,
      if (deepThinking) ...{
        'enable_thinking': true,
        'thinking_budget': 5120,
      },
    });

    final data = response.data as Map<String, dynamic>;
    // NestJS 包装响应为 {code, data, message}，需兼容
    final aiData = data['data'] ?? data;
    return aiData['choices']?[0]?['message']?['content'] ?? '抱歉，我无法回答这个问题。';
  }

  /// 语音转文字 - 通过后端代理
  Future<String> speechToText(List<int> audioBytes, String fileName, [String mimeType = 'audio/m4a']) async {
    // 解析主类型和子类型，如 'audio/webm' → ('audio', 'webm')
    final parts = mimeType.split('/');
    final mainType = parts.isNotEmpty ? parts[0] : 'audio';
    final subType = parts.length > 1 ? parts[1] : 'm4a';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioBytes,
        filename: fileName,
        contentType: DioMediaType(mainType, subType),
      ),
    });

    final response = await _dio.post(
      '/ai-proxy/audio/transcriptions',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // 后端 TransformInterceptor 包装：{ code, message, data: { text } }
    final inner = response.data['data'];
    if (inner is Map) {
      return inner['text'] ?? '';
    }
    return response.data['text'] ?? '';
  }

  /// 上传文档到 RAG 知识库
  Future<RagDocumentModel> uploadDocument(File file, {String? conversationId}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _dio.post(
      '/ai-proxy/rag/documents',
      data: formData,
      queryParameters: {
        if (conversationId != null) 'conversationId': conversationId,
      },
    );
    return RagDocumentModel.fromJson(response.data['data']);
  }

  /// 获取用户 RAG 文档列表
  Future<List<RagDocumentModel>> listDocuments({String? conversationId}) async {
    final response = await _dio.get(
      '/ai-proxy/rag/documents',
      queryParameters: {
        if (conversationId != null) 'conversationId': conversationId,
      },
    );
    final list = response.data['data'] as List;
    return list.map((j) => RagDocumentModel.fromJson(j)).toList();
  }

  /// 删除 RAG 文档
  Future<void> deleteDocument(String documentId) async {
    await _dio.delete('/ai-proxy/rag/documents/$documentId');
  }
}
