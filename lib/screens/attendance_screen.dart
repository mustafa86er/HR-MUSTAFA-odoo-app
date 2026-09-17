import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/attendance_service.dart';
import '../services/odoo_client.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AttendanceService();
  AttendanceRecord? _open;
  List<AttendanceRecord> _history = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employeeId = context.read<AppState>().currentEmployee!.employeeId;
    setState(() => _loading = true);
    try {
      final open = await _service.getOpenAttendance(employeeId);
      final history = await _service.getHistory(employeeId);
      setState(() {
        _open = open;
        _history = history;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is OdooException ? e.message : e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final employeeId = context.read<AppState>().currentEmployee!.employeeId;
    setState(() => _busy = true);
    try {
      if (_open == null) {
        await _service.checkIn(employeeId);
      } else {
        await _service.checkOut(_open!.id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is OdooException ? e.message : e.toString())),
        );
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    _open == null ? Icons.login : Icons.logout,
                    size: 56,
                    color: _open == null ? Colors.teal : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _open == null ? 'أنت غير مسجّل حضور حاليًا' : 'مسجّل دخول منذ',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_open != null)
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(_open!.checkIn.toLocal()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _toggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _open == null ? Colors.teal : Colors.orange,
                      ),
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(_open == null ? Icons.fingerprint : Icons.exit_to_app),
                      label: Text(_open == null ? 'تسجيل حضور' : 'تسجيل انصراف'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('سجل الحضور الأخير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._history.map((r) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text(DateFormat('yyyy-MM-dd').format(r.checkIn.toLocal())),
                  subtitle: Text(
                    'دخول: ${DateFormat('HH:mm').format(r.checkIn.toLocal())}'
                    '${r.checkOut != null ? '  •  خروج: ${DateFormat('HH:mm').format(r.checkOut!.toLocal())}' : '  •  مستمر'}',
                  ),
                  trailing: r.workedHours != null
                      ? Text('${r.workedHours!.toStringAsFixed(2)} س')
                      : null,
                ),
              )),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا يوجد سجل حضور بعد')),
            ),
        ],
      ),
    );
  }
}
