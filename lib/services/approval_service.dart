import '../config/odoo_config.dart';
import 'odoo_client.dart';

/// طلب موافقة عام (approval.request) - نستخدمه هنا لتصحيح الحضور
/// عبر تطبيق "الموافقات" (Approvals) القياسي في Odoo، بدون أي موديول مخصص.
/// يجب إنشاء فئة (Category) باسم [OdooConfig.attendanceCorrectionCategoryName]
/// مرة واحدة من: Odoo > Approvals > Configuration > Approval Categories.
class ApprovalRequest {
    final int id;
    final String name;
    final String requestOwnerName;
    final String status; // new, pending, approved, refused, cancel
    final String? reason;
    final DateTime? dateStart;

    ApprovalRequest({
          required this.id,
          required this.name,
          required this.requestOwnerName,
          required this.status,
          this.reason,
          this.dateStart,
    });

    static String _rel(dynamic v) => (v is List && v.length > 1) ? v[1].toString() : '';

    factory ApprovalRequest.fromOdoo(Map<String, dynamic> row) {
          return ApprovalRequest(
                  id: row['id'] as int,
                  name: row['name']?.toString() ?? '',
                  requestOwnerName: _rel(row['request_owner_id']),
                  status: row['request_status']?.toString() ?? 'new',
                  reason: row['reason']?.toString(),
                  dateStart: (row['date_start'] != null && row['date_start'] != false)
                      ? DateTime.tryParse((row['date_start'] as String).replaceFirst(' ', 'T'))
                      : null,
                );
    }

    String get statusLabel {
          switch (status) {
            case 'new':
                      return 'جديد';
            case 'pending':
                      return 'بانتظار الموافقة';
            case 'approved':
                      return 'مقبول';
            case 'refused':
                      return 'مرفوض';
            case 'cancel':
                      return 'ملغى';
            default:
                      return status;
          }
    }
}

class ApprovalService {
    final OdooClient _client = OdooClient.instance;

    /// يبحث عن فئة "تصحيح حضور" التي يجب إنشاؤها مسبقًا في Odoo (بدون كود)
    Future<int?> _findCorrectionCategoryId() async {
          final rows = await _client.searchRead(
                  'approval.category',
                  domain: [
                            ['name', '=', OdooConfig.attendanceCorrectionCategoryName],
                          ],
                  fields: ['id'],
                  limit: 1,
                );
          if (rows.isEmpty) return null;
          return rows.first['id'] as int;
    }

    /// إنشاء طلب تصحيح حضور جديد من الموظف نفسه
    Future<void> createAttendanceCorrection({
          required String reason,
          required DateTime date,
    }) async {
          final categoryId = await _findCorrectionCategoryId();
          if (categoryId == null) {
                  throw OdooException(
                            'لم يتم إعداد فئة "${OdooConfig.attendanceCorrectionCategoryName}" في تطبيق الموافقات على Odoo بعد. '
                            'يرجى إنشائها مرة واحدة من: الموافقات > الإعدادات > فئات الموافقة.',
                          );
          }
          final id = await _client.create('approval.request', {
                  'name': 'تصحيح حضور - ${_fmtDate(date)}',
                  'category_id': categoryId,
                  'date_start': _fmtDateTime(date),
                  'reason': reason,
          });
          // بعض إصدارات أودو تتطلب تأكيد الطلب صراحة لإرساله للموافقة
          try {
                  await _client.callMethod('approval.request', 'action_confirm', [id]);
          } catch (_) {
                  // إن لم تتوفر الدالة أو الطلب يُرسل تلقائيًا، نتجاهل بصمت
          }
    }

    Future<List<ApprovalRequest>> getMyRequests() async {
          final categoryId = await _findCorrectionCategoryId();
          if (categoryId == null) return [];
          final rows = await _client.searchRead(
                  'approval.request',
                  domain: [
                            ['category_id', '=', categoryId],
                          ],
                  fields: ['id', 'name', 'request_owner_id', 'request_status', 'reason', 'date_start'],
                  order: 'date_start desc',
                );
          return rows.map((r) => ApprovalRequest.fromOdoo(r)).toList();
    }

    /// الطلبات التي تنتظر موافقة المستخدم الحالي (كموافق/مدير)
    Future<List<ApprovalRequest>> getPendingApprovals() async {
          final categoryId = await _findCorrectionCategoryId();
          if (categoryId == null) return [];
          final rows = await _client.searchRead(
                  'approval.request',
                  domain: [
                            ['category_id', '=', categoryId],
                            ['request_status', '=', 'pending'],
                          ],
                  fields: ['id', 'name', 'request_owner_id', 'request_status', 'reason', 'date_start'],
                  order: 'date_start asc',
                );
          return rows.map((r) => ApprovalRequest.fromOdoo(r)).toList();
    }

    Future<void> approve(int id) async {
          await _client.callMethod('approval.request', 'action_approve', [id]);
    }

    Future<void> refuse(int id) async {
          await _client.callMethod('approval.request', 'action_refuse', [id]);
    }

    String _fmtDate(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
}
