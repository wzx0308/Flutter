class AppConstants {
  static const String appName = '安隅';
  static const String baseUrl = 'http://localhost:3000/api'; // Chrome / iOS simulator
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // AI Chat
  static const String aiApiKey = 'sk-cjgpxnv2nxvx2v33tdmbxps2zkj3ct2mth2p6u1zo4m3bqlr';
  static const String aiBaseUrl = 'https://api.xiaomimimo.com/v1';
  static const String aiModel = 'mimo-v2.5';
}
