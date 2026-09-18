import 'odoo_client.dart';

/// معلومات الموظف المرتبط بحساب المستخدم الحالي، ومعرفة هل هو مدير (لديه مرؤوسون)
class EmployeeProfile {
    final int employeeId;
    final String name;
    final String jobTitle;
    final int? managerId;
    final String? managerName;
    final bool isManager;
    final String? avatarUrl;
    final String? workEmail;
    final String? mobilePhone;
    final String? departmentName;

    EmployeeProfile({
          required this.employeeId,
          required this.name,
          required this.jobTitle,
          this.managerId,
          this.managerName,
          required this.isManager,
          this.avatarUrl,
          this.workEmail,
          this.mobilePhone,
          this.departmentName,
    });
}

class EmployeeService {
    final OdooClient _client = OdooClient.instance;

    /// يجلب سجل hr.employee المرتبط بالمستخدم الحالي (uid) عبر حقل user_id
    Future<EmployeeProfile> getCurrentEmployee() async {
          final uid = _client.uid;
          final rows = await _client.searchRead(
                  'hr.employee',
                  domain: [
                            ['user_id', '=', uid],
                          ],
                  fields: [
                            'id',
                            'name',
                            'job_title',
                            'parent_id',
                            'work_email',
                            'mobile_phone',
                            'department_id',
                          ],
                  limit: 1,
                );
          if (rows.isEmpty) {
                  throw OdooException(
                            'لا يوجد سجل موظف (hr.employee) مرتبط بحساب المستخدم هذا في Odoo',
                          );
          }
          final row = rows.first;
          final employeeId = row['id'] as int;

          // هل هذا الموظف مدير لأي موظف آخر؟ (لإظهار شاشة الموافقات)
          final subordinates = await _client.searchRead(
                  'hr.employee',
                  domain: [
                            ['parent_id', '=', employeeId],
                          ],
                  fields: ['id'],
                  limit: 1,
                );

          final parent = row['parent_id'];
          final dept = row['department_id'];
          return EmployeeProfile(
                  employeeId: employeeId,
                  name: row['name']?.toString() ?? '',
                  jobTitle: row['job_title']?.toString() ?? '',
                  managerId: (parent is List && parent.isNotEmpty) ? parent[0] as int : null,
                  managerName: (parent is List && parent.length > 1) ? parent[1].toString() : null,
                  isManager: subordinates.isNotEmpty,
                  workEmail: row['work_email'] == false ? null : row['work_email']?.toString(),
                  mobilePhone: row['mobile_phone'] == false ? null : row['mobile_phone']?.toString(),
                  departmentName: (dept is List && dept.length > 1) ? dept[1].toString() : null,
                );
    }
}
