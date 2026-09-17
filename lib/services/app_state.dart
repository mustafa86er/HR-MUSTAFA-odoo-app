import 'package:flutter/foundation.dart';
import 'odoo_client.dart';
import 'employee_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// حالة التطبيق العامة: تسجيل الدخول + بيانات الموظف الحالي (متاحة لكل الشاشات)
class AppState extends ChangeNotifier {
  final OdooClient _odoo = OdooClient.instance;
  final EmployeeService _employeeService = EmployeeService();

  AuthStatus status = AuthStatus.unknown;
  EmployeeProfile? currentEmployee;
  String? lastError;
  bool isLoading = false;

  Future<void> tryAutoLogin() async {
    isLoading = true;
    notifyListeners();
    final restored = await _odoo.restoreSession();
    if (restored) {
      try {
        currentEmployee = await _employeeService.getCurrentEmployee();
        status = AuthStatus.loggedIn;
      } catch (e) {
        status = AuthStatus.loggedOut;
      }
    } else {
      status = AuthStatus.loggedOut;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await _odoo.login(login: username, password: password);
      currentEmployee = await _employeeService.getCurrentEmployee();
      status = AuthStatus.loggedIn;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('OdooException(null): ', '');
      status = AuthStatus.loggedOut;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _odoo.logout();
    currentEmployee = null;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
