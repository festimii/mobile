class ApiRoutes {
  static const baseUrl = 'http://192.168.201.109:8080';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const register = '/auth/register';
  static const metrics = '/dashboard/metrics';
  static const storeSales = '/stores/sales';
  static String storeKpi(int id) => '/stores/$id/kpi';
  static const weeklySales = '/sales/weekly';
  static const hourlySales = '/sales/hourly';
  static const inventory = '/inventory';
  static const totpStatus = '/auth/totp-status';
  static const enableTotp = '/auth/enable-totp';
  static const disableTotp = '/auth/disable-totp';
}
