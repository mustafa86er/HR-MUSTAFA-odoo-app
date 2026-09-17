import 'odoo_client.dart';

class Payslip {
  final int id;
  final String name;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String state;
  final double? netWage;

  Payslip({
    required this.id,
    required this.name,
    required this.dateFrom,
    required this.dateTo,
    required this.state,
    this.netWage,
  });

  factory Payslip.fromOdoo(Map<String, dynamic> row) {
    return Payslip(
      id: row['id'] as int,
      name: row['name']?.toString() ?? '',
      dateFrom: DateTime.parse(row['date_from'].toString()),
      dateTo: DateTime.parse(row['date_to'].toString()),
      state: row['state']?.toString() ?? 'draft',
      netWage: (row['net_wage'] as num?)?.toDouble(),
    );
  }

  String get stateLabel {
    switch (state) {
      case 'draft':
        return 'مسودة';
      case 'verify':
        return 'قيد المراجعة';
      case 'done':
        return 'معتمد';
      case 'paid':
        return 'مدفوع';
      case 'cancel':
        return 'ملغى';
      default:
        return state;
    }
  }
}

/// خدمة الرواتب - تعمل على موديل hr.payslip (يتطلب تفعيل Payroll في Odoo)
/// ملاحظة: صافي الراتب (net_wage) غير موجود كحقل مباشر دائمًا فى بعض الإصدارات،
/// لذلك نجلبه أيضًا من payslip line المرتبطة بقاعدة الأجر NET عند الحاجة.
class PayslipService {
  final OdooClient _client = OdooClient.instance;

  Future<List<Payslip>> getMyPayslips(int employeeId, {int limit = 24}) async {
    final rows = await _client.searchRead(
      'hr.payslip',
      domain: [
        ['employee_id', '=', employeeId],
      ],
      fields: ['id', 'name', 'date_from', 'date_to', 'state'],
      order: 'date_from desc',
      limit: limit,
    );

    final payslips = rows.map((r) => Payslip.fromOdoo(r)).toList();

    // محاولة إثراء البيانات بصافي الراتب من hr.payslip.line (code = NET)
    for (var i = 0; i < payslips.length; i++) {
      try {
        final lines = await _client.searchRead(
          'hr.payslip.line',
          domain: [
            ['slip_id', '=', payslips[i].id],
            ['code', '=', 'NET'],
          ],
          fields: ['total'],
          limit: 1,
        );
        if (lines.isNotEmpty) {
          final net = (lines.first['total'] as num?)?.toDouble();
          if (net != null) {
            payslips[i] = Payslip(
              id: payslips[i].id,
              name: payslips[i].name,
              dateFrom: payslips[i].dateFrom,
              dateTo: payslips[i].dateTo,
              state: payslips[i].state,
              netWage: net,
            );
          }
        }
      } catch (_) {
        // تجاهل بصمت إن لم يكن الحقل/الموديل متاحًا لهذا المستخدم
      }
    }
    return payslips;
  }
}
