/// Defines endpoints used by the application.
class ApiRoutes {
  static const baseUrl = 'http://192.168.200.246:8080';

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
