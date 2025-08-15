class ApiRoutes {
  /// Base URL for the backend service. Updated to use localhost so the
  /// Flutter app can communicate with the Spring Boot server running on the
  /// same machine or emulator.
  static const baseUrl = 'http://192.168.178.102:8080';

  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const register = '/auth/register';
  static const metrics = '/dashboard/metrics';
  static const storeSales = '/stores/sales';
  static const weeklySales = '/sales/weekly';
  static const hourlySales = '/sales/hourly';
  static const inventory = '/inventory';
  static const totpStatus = '/auth/totp-status';
  static const enableTotp = '/auth/enable-totp';
  static const disableTotp = '/auth/disable-totp';
}
