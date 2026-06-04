import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../../core/storage/storage_service.dart';

class UserRepository {
  final UserProvider _provider = UserProvider();
  final StorageService _storage = StorageService.to;

  Future<UserModel> getMe() async {
    final res = await _provider.getMe();
    if (res['code'] == 0) {
      final user = UserModel.fromJson(res['data']);
      await _storage.saveUser(res['data']);
      return user;
    }
    throw Exception(res['message'] ?? '获取用户信息失败');
  }

  Future<UserModel> updateMe(Map<String, dynamic> data) async {
    final res = await _provider.updateMe(data);
    if (res['code'] == 0) {
      final user = UserModel.fromJson(res['data']);
      await _storage.saveUser(res['data']);
      return user;
    }
    throw Exception(res['message'] ?? '更新失败');
  }

  Future<UserModel> getUserById(String id) async {
    final res = await _provider.getUserById(id);
    if (res['code'] == 0) {
      return UserModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? '获取用户信息失败');
  }
}
