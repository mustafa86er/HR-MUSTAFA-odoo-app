import 'odoo_client.dart';

class LeaveType {
  final int id;
  final String name;
  LeaveType({required this.id, required this.name});
}

class LeaveRequest {
  final int id;
  final String employeeName;
  final String leaveTypeName;
  final DateTime dateFrom;
  final DateTime dateTo;
  final double numberOfDays;
  final String state; // draft, confirm, refuse, validate1, validate
  final String? description;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveTypeName,
    required this.dateFrom,
    required this.dateTo,
    required this.numberOfDays,
    required this.state,
    this.description,
  });

  static String _rel(dynamic v) => (v is List && v.length > 1) ? v[1].toString() : '';

  factory LeaveRequest.fromOdoo(Map<String, dynamic> row) {
    return LeaveRequest(
      id: row['id'] as int,
      employeeName: _rel(row['employee_id']),
      leaveTypeName: _rel(row['holiday_status_id']),
      dateFrom: DateTime.parse((row['date_from'] as String).replaceFirst(' ', 'T')),
      dateTo: DateTime.parse((row['date_to'] as String).replaceFirst(' ', 'T')),
      numberOfDays: (row['number_of_days'] as num?)?.toDouble() ?? 0,
      state: row['state']?.toString() ?? 'draft',
      description: row['name']?.toString(),
    );
  }

  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'مسودة';
      case 'confirm':
        return 'بانتظار الموافقة';
      case 'validate1':
        return 'موافقة أولى';
      case 'validate':
        return 'مقبولة';
      case 'refuse':
        return 'مرفوضة';
      default:
        return state;
    }
  }
}

/// خدمة الإجازات - تعمل على موديل hr.leave
class LeaveService {
  final OdooClient _client = OdooClient.instance;

  Future<List<LeaveType>> getLeaveTypes() async {
    final rows = await _client.searchRead(
      'hr.leave.type',
      fields: ['id', 'name'],
    );
    return rows.map((r) => LeaveType(id: r['id'] as int, name: r['name'].toString())).toList();
  }

  Future<List<LeaveRequest>> getMyLeaves(int employeeId) async {
    final rows = await _client.searchRead(
      'hr.leave',
      domain: [
        ['employee_id', '=', employeeId],
      ],
      fields: [
        'id',
        'employee_id',
        'holiday_status_id',
        'date_from',
        'date_to',
        'number_of_days',
        'state',
        'name',
      ],
      order: 'date_from desc',
    );
    return rows.map((r) => LeaveRequest.fromOdoo(r)).toList();
  }

  /// طلبات الإجازة التي تنتظر موافقة المدير الحالي (لموظفيه المباشرين)
  Future<List<LeaveRequest>> getPendingApprovals(int managerEmployeeId) async {
    final rows = await _client.searchRead(
      'hr.leave',
      domain: [
        ['employee_id.parent_id', '=', managerEmployeeId],
        ['state', 'in', ['confirm', 'validate1']],
      ],
      fields: [
        'id',
        'employee_id',
        'holiday_status_id',
        'date_from',
        'date_to',
        'number_of_days',
        'state',
        'name',
      ],
      order: 'date_from asc',
    );
    return rows.map((r) => LeaveRequest.fromOdoo(r)).toList();
  }

  Future<void> createLeaveRequest({
    required int employeeId,
    required int leaveTypeId,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? reason,
  }) async {
    await _client.create('hr.leave', {
      'employee_id': employeeId,
      'holiday_status_id': leaveTypeId,
      'date_from': _fmt(dateFrom),
      'date_to': _fmt(dateTo),
      if (reason != null && reason.isNotEmpty) 'name': reason,
    });
  }

  /// اعتماد الطلب - يستدعي action_approve أو action_validate حسب حالة سير العمل في Odoo
  Future<void> approve(int leaveId) async {
    await _client.callMethod('hr.leave', 'action_approve', [leaveId]);
  }

  Future<void> refuse(int leaveId) async {
    await _client.callMethod('hr.leave', 'action_refuse', [leaveId]);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} 00:00:00';
}
