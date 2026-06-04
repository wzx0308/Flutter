import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/app_constants.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // ════════════════ Token ════════════════

  Future<void> saveToken(String token) => _box.write(AppConstants.tokenKey, token);
  String? getToken() => _box.read<String>(AppConstants.tokenKey);
  Future<void> removeToken() => _box.remove(AppConstants.tokenKey);

  // ════════════════ Refresh Token ════════════════

  Future<void> saveRefreshToken(String token) => _box.write(AppConstants.refreshTokenKey, token);
  String? getRefreshToken() => _box.read<String>(AppConstants.refreshTokenKey);
  Future<void> removeRefreshToken() => _box.remove(AppConstants.refreshTokenKey);

  // ════════════════ User data ════════════════

  Future<void> saveUser(Map<String, dynamic> user) => _box.write(AppConstants.userKey, user);
  Map<String, dynamic>? getUser() => _box.read<Map<String, dynamic>>(AppConstants.userKey);
  Future<void> removeUser() => _box.remove(AppConstants.userKey);

  // ════════════════ Clear auth only (保留背景、AI、搜索历史) ════════════════

  Future<void> clearAll() async {
    await removeToken();
    await removeRefreshToken();
    await removeUser();
  }

  // ════════════════ User Background (per-user, survives logout) ════════════════

  static const String _bgPrefix = 'user_bg_';

  String _bgKey(String userId) => '$_bgPrefix$userId';

  Map<String, dynamic> getUserBackground(String userId) =>
      _box.read<Map<String, dynamic>>(_bgKey(userId)) ?? {};

  Future<void> saveUserBackground(String userId, {int? bgIndex, String? customUrl}) async {
    final data = getUserBackground(userId);
    if (bgIndex != null) data['bgIndex'] = bgIndex;
    if (customUrl != null) data['customBackgroundUrl'] = customUrl;
    await _box.write(_bgKey(userId), data);
  }

  bool get isLoggedIn => getToken() != null;

  // ════════════════ AI Chat Persistence ════════════════

  static const String _aiConversationsKey = 'ai_conversations';
  static const String _aiMessagesPrefix = 'ai_messages_';

  Future<void> saveAiConversations(List<Map<String, dynamic>> list) =>
      _box.write(_aiConversationsKey, list);

  List<Map<String, dynamic>> getAiConversations() =>
      _box.read<List>(_aiConversationsKey)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> saveAiMessages(String conversationId, List<Map<String, dynamic>> messages) =>
      _box.write('$_aiMessagesPrefix$conversationId', messages);

  List<Map<String, dynamic>> getAiMessages(String conversationId) =>
      _box.read<List>('$_aiMessagesPrefix$conversationId')?.cast<Map<String, dynamic>>() ?? [];

  Future<void> deleteAiMessages(String conversationId) =>
      _box.remove('$_aiMessagesPrefix$conversationId');

  // ════════════════ Search History ════════════════

  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;

  List<String> getSearchHistory() =>
      _box.read<List>(_searchHistoryKey)?.cast<String>() ?? [];

  Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final list = getSearchHistory();
    list.removeWhere((item) => item == query);
    list.insert(0, query);
    if (list.length > _maxHistoryItems) {
      list.removeRange(_maxHistoryItems, list.length);
    }
    await _box.write(_searchHistoryKey, list);
  }

  Future<void> removeSearchHistory(String query) async {
    final list = getSearchHistory();
    list.remove(query);
    await _box.write(_searchHistoryKey, list);
  }

  Future<void> clearSearchHistory() async {
    await _box.remove(_searchHistoryKey);
  }
}
