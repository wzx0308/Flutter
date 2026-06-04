import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../../core/storage/storage_service.dart';

class AuthRepository {
  final AuthProvider _provider = AuthProvider();
  final StorageService _storage = StorageService.to;

  Future<UserModel> register({
    String? username,
    String? email,
    String? phone,
    required String password,
    String? nickname,
  }) async {
    final res = await _provider.register(
      username: username,
      email: email,
      phone: phone,
      password: password,
      nickname: nickname,
    );
    if (res['code'] == 0) {
      final data = res['data'];
      await _saveAuthData(data);
      return UserModel.fromJson(data['user']);
    }
    throw Exception(res['message'] ?? '注册失败');
  }

  Future<UserModel> login({
    required String account,
    required String password,
  }) async {
    final res = await _provider.login(account: account, password: password);
    if (res['code'] == 0) {
      final data = res['data'];
      await _saveAuthData(data);
      return UserModel.fromJson(data['user']);
    }
    throw Exception(res['message'] ?? '登录失败');
  }

  Future<UserModel> loginBySms({
    required String phone,
    required String code,
  }) async {
    final res = await _provider.loginBySms(phone: phone, code: code);
    if (res['code'] == 0) {
      final data = res['data'];
      await _saveAuthData(data);
      return UserModel.fromJson(data['user']);
    }
    throw Exception(res['message'] ?? '登录失败');
  }

  Future<void> sendSmsCode(String phone) async {
    final res = await _provider.sendSmsCode(phone);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '发送失败');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.saveToken(data['accessToken']);
    await _storage.saveRefreshToken(data['refreshToken']);
    await _storage.saveUser(data['user']);
  }
}
