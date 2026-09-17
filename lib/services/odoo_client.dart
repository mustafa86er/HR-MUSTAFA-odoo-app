import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/odoo_config.dart';

/// استثناء مخصص لأخطاء Odoo (يفرّق بين خطأ شبكة وخطأ صلاحيات/بيانات)
class OdooException implements Exception {
  final String message;
  final int? code;
  OdooException(this.message, {this.code});
  @override
  String toString() => 'OdooException($code): $message';
}

/// طبقة الاتصال الأساسية بـ Odoo عبر بروتوكول JSON-RPC 2.0.
/// لا تحتاج أي موديول مخصص داخل Odoo - تعمل على أي Odoo Enterprise/Community
/// طالما أن الحساب المستخدم لديه صلاحيات القراءة/الكتابة المناسبة.
class OdooClient {
  OdooClient._internal();
  static final OdooClient instance = OdooClient._internal();

  final _storage = const FlutterSecureStorage();
  int? uid;
  String? _password;
  String? _db;

  static const _kUidKey = 'odoo_uid';
  static const _kPasswordKey = 'odoo_password';
  static const _kLoginKey = 'odoo_login';
  static const _kDbKey = 'odoo_db';

  bool get isAuthenticated => uid != null && _password != null;

  Uri get _jsonRpcUri => Uri.parse('${OdooConfig.baseUrl}/jsonrpc');

  Future<Map<String, dynamic>> _call(
    String service,
    String method,
    List<dynamic> args,
  ) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'service': service,
        'method': method,
        'args': args,
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    });

    http.Response resp;
    try {
      resp = await http
          .post(
            _jsonRpcUri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(Duration(seconds: OdooConfig.timeoutSeconds));
    } catch (e) {
      throw OdooException('تعذر الاتصال بالخادم: $e');
    }

    if (resp.statusCode != 200) {
      throw OdooException('خطأ خادم HTTP ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (decoded['error'] != null) {
      final err = decoded['error'];
      final data = err['data'] ?? {};
      final msg = data['message'] ?? err['message'] ?? 'خطأ غير معروف من Odoo';
      throw OdooException(msg.toString(), code: err['code']);
    }
    return decoded;
  }

  /// تسجيل الدخول عبر common.authenticate ثم تخزين بيانات الجلسة محليًا (مشفّرة)
  Future<int> login({
    required String login,
    required String password,
    String? db,
  }) async {
    final database = db ?? OdooConfig.database;
    final result = await _call('common', 'authenticate', [
      database,
      login,
      password,
      {},
    ]);
    final id = result['result'];
    if (id == null || id == false) {
      throw OdooException('بيانات الدخول غير صحيحة');
    }
    uid = id as int;
    _password = password;
    _db = database;

    await _storage.write(key: _kUidKey, value: uid.toString());
    await _storage.write(key: _kPasswordKey, value: password);
    await _storage.write(key: _kLoginKey, value: login);
    await _storage.write(key: _kDbKey, value: database);
    return uid!;
  }

  /// استرجاع جلسة محفوظة سابقًا (Auto-login) عند فتح التطبيق
  Future<bool> restoreSession() async {
    final storedUid = await _storage.read(key: _kUidKey);
    final storedPassword = await _storage.read(key: _kPasswordKey);
    final storedDb = await _storage.read(key: _kDbKey);
    if (storedUid == null || storedPassword == null) return false;
    uid = int.tryParse(storedUid);
    _password = storedPassword;
    _db = storedDb ?? OdooConfig.database;
    return uid != null;
  }

  Future<void> logout() async {
    uid = null;
    _password = null;
    await _storage.delete(key: _kUidKey);
    await _storage.delete(key: _kPasswordKey);
    await _storage.delete(key: _kLoginKey);
    await _storage.delete(key: _kDbKey);
  }

  /// نداء عام لأي دالة عبر object.execute_kw
  /// مثال: executeKw('hr.attendance', 'search_read', [[...domain]], {'fields': [...]})
  Future<dynamic> executeKw(
    String model,
    String method,
    List<dynamic> args, {
    Map<String, dynamic>? kwargs,
  }) async {
    if (!isAuthenticated) {
      throw OdooException('الجلسة غير مفعّلة، الرجاء تسجيل الدخول من جديد');
    }
    final result = await _call('object', 'execute_kw', [
      _db,
      uid,
      _password,
      model,
      method,
      args,
      kwargs ?? {},
    ]);
    return result['result'];
  }

  Future<List<Map<String, dynamic>>> searchRead(
    String model, {
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int? limit,
    String? order,
    int offset = 0,
  }) async {
    final result = await executeKw(
      model,
      'search_read',
      [domain],
      kwargs: {
        'fields': fields,
        if (limit != null) 'limit': limit,
        if (order != null) 'order': order,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<int> create(String model, Map<String, dynamic> values) async {
    final result = await executeKw(model, 'create', [values]);
    return result as int;
  }

  Future<bool> write(
    String model,
    List<int> ids,
    Map<String, dynamic> values,
  ) async {
    final result = await executeKw(model, 'write', [ids, values]);
    return result as bool;
  }

  Future<dynamic> callMethod(
    String model,
    String method,
    List<int> ids, {
    List<dynamic> extraArgs = const [],
  }) async {
    return executeKw(model, method, [ids, ...extraArgs]);
  }
}
