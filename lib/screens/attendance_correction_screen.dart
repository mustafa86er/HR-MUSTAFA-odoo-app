import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/approval_service.dart';
import '../services/odoo_client.dart';

/// شاشة "طلب تصحيح حضور" - يستخدمها الموظف عند نسيان تسجيل حضور/انصراف.
/// يُرسل الطلب عبر تطبيق الموافقات (Approvals) القياسي في Odoo، ويعتمده
/// المدير مباشرة من شاشة "الموافقات" داخل هذا التطبيق دون فتح Odoo.
class AttendanceCorrectionScreen extends StatefulWidget {
    const AttendanceCorrectionScreen({super.key});

    @override
    State<AttendanceCorrectionScreen> createState() => _AttendanceCorrectionScreenState();
}

class _AttendanceCorrectionScreenState extends State<AttendanceCorrectionScreen> {
    final _service = ApprovalService();
    final _reasonController = TextEditingController();
    DateTime _date = DateTime.now();
    bool _sending = false;

    @override
    void dispose() {
          _reasonController.dispose();
          super.dispose();
    }

    Future<void> _pickDate() async {
          final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
          if (picked != null) {
                  final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_date),
                          );
                  setState(() {
                            _date = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        time?.hour ?? _date.hour,
                                        time?.minute ?? _date.minute,
                                      );
                  });
          }
    }

    Future<void> _submit() async {
          if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة سبب طلب التصحيح')),
                          );
                  return;
          }
          setState(() => _sending = true);
          try {
                  await _service.createAttendanceCorrection(
                            reason: _reasonController.text.trim(),
                            date: _date,
                          );
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم إرسال طلب التصحيح بانتظار موافقة المدير')),
                                      );
                            Navigator.of(context).pop();
                  }
          } catch (e) {
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e is OdooException ? e.message : e.toString())),
                                      );
                  }
          } finally {
                  if (mounted) setState(() => _sending = false);
          }
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(title: const Text('طلب تصحيح حضور')),
                  body: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                                        const Text(
                                                      'استخدم هذا النموذج إذا نسيت تسجيل الحضور أو الانصراف في الوقت الصحيح. '
                                                      'سيُرسل الطلب لمديرك المباشر للموافقة عليه من داخل التطبيق.',
                                                      style: TextStyle(color: Colors.grey),
                                                    ),
                                        const SizedBox(height: 20),
                                        Card(
                                                      child: ListTile(
                                                                      leading: const Icon(Icons.calendar_today, color: Colors.teal),
                                                                      title: const Text('تاريخ ووقت الحضور/الانصراف الصحيح'),
                                                                      subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_date)),
                                                                      trailing: const Icon(Icons.edit),
                                                                      onTap: _pickDate,
                                                                    ),
                                                    ),
                                        const SizedBox(height: 16),
                                        TextField(
                                                      controller: _reasonController,
                                                      maxLines: 3,
                                                      decoration: const InputDecoration(
                                                                      labelText: 'سبب طلب التصحيح',
                                                                      border: OutlineInputBorder(),
                                                                      hintText: 'مثال: نسيت تسجيل الانصراف يوم الأحد',
                                                                    ),
                                                    ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                                      height: 50,
                                                      child: ElevatedButton.icon(
                                                                      onPressed: _sending ? null : _submit,
                                                                      icon: _sending
                                                                          ? const SizedBox(
                                                                                                  height: 18,
                                                                                                  width: 18,
                                                                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                                                )
                                                                          : const Icon(Icons.send),
                                                                      label: const Text('إرسال الطلب'),
                                                                    ),
                                                    ),
                                      ],
                          ),
                );
    }
}
