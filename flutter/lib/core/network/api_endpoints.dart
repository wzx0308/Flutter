class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginSms = '/auth/login/sms';
  static const String sendSms = '/auth/send-sms';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String userMe = '/users/me';
  static String userById(String id) => '/users/$id';

  // Wallet
  static const String walletBalance = '/wallet/balance';
  static const String walletRecharge = '/wallet/recharge';
  static const String walletTransactions = '/wallet/transactions';

  // Payment Password
  static const String paymentPasswordStatus = '/wallet/payment-password/status';
  static const String paymentPasswordSet = '/wallet/payment-password/set';
  static const String paymentPasswordVerify = '/wallet/payment-password/verify';

  // Transfer
  static const String transferCreate = '/transfer';
  static String transferAccept(String id) => '/transfer/$id/accept';
  static String transferRefund(String id) => '/transfer/$id/refund';
  static String transferDetail(String id) => '/transfer/$id';
  static const String transferList = '/transfer/list';
}
