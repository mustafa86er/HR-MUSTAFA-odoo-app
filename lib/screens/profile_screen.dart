import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

/// شاشة الملف الشخصي للموظف الحالي.
class ProfileScreen extends StatelessWidget {
    const ProfileScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final employee = context.watch<AppState>().currentEmployee;

          return Scaffold(
                  appBar: AppBar(title: const Text('الملف الشخصي')),
                  body: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                                        Center(
                                                      child: CircleAvatar(
                                                                      radius: 52,
                                                                      backgroundColor: const Color(0xFF1E4A8C),
                                                                      child: Text(
                                                                                        (employee?.name.isNotEmpty ?? false) ? employee!.name.substring(0, 1) : '?',
                                                                                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                                                                                      ),
                                                                    ),
                                                    ),
                                        const SizedBox(height: 14),
                                        Center(
                                                      child: Text(
                                                                      employee?.name ?? '',
                                                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                                    ),
                                                    ),
                                        if (employee?.jobTitle.isNotEmpty ?? false)
                                          Center(
                                                          child: Text(
                                                                            employee!.jobTitle,
                                                                            style: const TextStyle(color: Colors.grey),
                                                                          ),
                                                        ),
                                        const SizedBox(height: 24),
                                        Card(
                                                      child: Column(
                                                                      children: [
                                                                                        ListTile(
                                                                                                            leading: const Icon(Icons.apartment, color: Color(0xFF1E4A8C)),
                                                                                                            title: const Text('القسم'),
                                                                                                            subtitle: Text(employee?.departmentName ?? 'غير محدد'),
                                                                                                          ),
                                                                                        const Divider(height: 1),
                                                                                        ListTile(
                                                                                                            leading: const Icon(Icons.supervisor_account, color: Color(0xFF1E4A8C)),
                                                                                                            title: const Text('المدير المباشر'),
                                                                                                            subtitle: Text(employee?.managerName ?? 'غير محدد'),
                                                                                                          ),
                                                                                        const Divider(height: 1),
                                                                                        ListTile(
                                                                                                            leading: const Icon(Icons.email_outlined, color: Color(0xFF1E4A8C)),
                                                                                                            title: const Text('البريد الإلكتروني'),
                                                                                                            subtitle: Text(employee?.workEmail ?? 'غير مسجّل'),
                                                                                                          ),
                                                                                        const Divider(height: 1),
                                                                                        ListTile(
                                                                                                            leading: const Icon(Icons.phone_outlined, color: Color(0xFF1E4A8C)),
                                                                                                            title: const Text('رقم الجوال'),
                                                                                                            subtitle: Text(employee?.mobilePhone ?? 'غير مسجّل'),
                                                                                                          ),
                                                                                      ],
                                                                    ),
                                                    ),
                                      ],
                          ),
                );
    }
}
