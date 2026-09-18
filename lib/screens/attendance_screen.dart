import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/attendance_service.dart';
import '../services/odoo_client.dart';
import 'attendance_correction_screen.dart';

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
    Timer? _ticker;
    Duration _elapsed = Duration.zero;

    @override
    void initState() {
          super.initState();
          _load();
          _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }

    @override
    void dispose() {
          _ticker?.cancel();
          super.dispose();
    }

    void _tick() {
          if (_open == null) {
                  if (_elapsed != Duration.zero) setState(() => _elapsed = Duration.zero);
                  return;
          }
          setState(() {
                  _elapsed = DateTime.now().toUtc().difference(_open!.checkIn);
          });
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

    String _two(int n) => n.toString().padLeft(2, '0');

    @override
    Widget build(BuildContext context) {
          final app = context.watch<AppState>();
          final h = _two(_elapsed.inHours);
          final m = _two(_elapsed.inMinutes.remainder(60));
          final s = _two(_elapsed.inSeconds.remainder(60));

          if (_loading) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                                        Text(
                                                      'مرحباً، ${app.currentEmployee?.name ?? ''}',
                                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                    ),
                                        const SizedBox(height: 16),
                                        if (_error != null)
                                          Card(
                                                          color: Colors.red.shade50,
                                                          child: Padding(
                                                                            padding: const EdgeInsets.all(12),
                                                                            child: Text(_error!, style: const TextStyle(color: Colors.red)),
                                                                          ),
                                                        ),
                                        Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                                                      decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(24),
                                                                      gradient: LinearGradient(
                                                                                        begin: Alignment.topLeft,
                                                                                        end: Alignment.bottomRight,
                                                                                        colors: _open == null
                                                                                            ? [const Color(0xFF1E4A8C), const Color(0xFF102852)]
                                                                                            : [const Color(0xFF00897B), const Color(0xFF00332B)],
                                                                                      ),
                                                                      boxShadow: [
                                                                                        BoxShadow(
                                                                                                            color: (_open == null ? const Color(0xFF1E4A8C) : const Color(0xFF00897B))
                                                                                                                .withOpacity(0.35),
                                                                                                            blurRadius: 20,
                                                                                                            offset: const Offset(0, 10),
                                                                                                          ),
                                                                                      ],
                                                                    ),
                                                      child: Column(
                                                                      children: [
                                                                                        Text(
                                                                                                            _open == null ? 'غير مسجّل حضور حالياً' : 'وقت العمل المستمر',
                                                                                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                                                                                          ),
                                                                                        const SizedBox(height: 14),
                                                                                        Text(
                                                                                                            '$h : $m : $s',
                                                                                                            style: const TextStyle(
                                                                                                                                  color: Colors.white,
                                                                                                                                  fontSize: 46,
                                                                                                                                  fontWeight: FontWeight.bold,
                                                                                                                                  letterSpacing: 2,
                                                                                                                                ),
                                                                                                          ),
                                                                                        if (_open != null) ...[
                                                                                                            const SizedBox(height: 6),
                                                                                                            Text(
                                                                                                                                  'منذ ${DateFormat('HH:mm').format(_open!.checkIn.toLocal())}',
                                                                                                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                                                                                                ),
                                                                                                          ],
                                                                                        const SizedBox(height: 22),
                                                                                        SizedBox(
                                                                                                            width: double.infinity,
                                                                                                            height: 52,
                                                                                                            child: ElevatedButton.icon(
                                                                                                                                  onPressed: _busy ? null : _toggle,
                                                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                                                                          backgroundColor: Colors.white,
                                                                                                                                                          foregroundColor: _open == null ? const Color(0xFF1E4A8C) : const Color(0xFF00897B),
                                                                                                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                                                                                                                        ),
                                                                                                                                  icon: _busy
                                                                                                                                      ? const SizedBox(
                                                                                                                                                                    height: 18,
                                                                                                                                                                    width: 18,
                                                                                                                                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                                                                                                                                  )
                                                                                                                                      : Icon(_open == null ? Icons.login : Icons.logout),
                                                                                                                                  label: Text(
                                                                                                                                                          _open == null ? 'تسجيل حضور' : 'تسجيل انصراف',
                                                                                                                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                          ),
                                                                                      ],
                                                                    ),
                                                    ),
                                        const SizedBox(height: 14),
                                        OutlinedButton.icon(
                                                      onPressed: () {
                                                                      Navigator.of(context).push(
                                                                                        MaterialPageRoute(builder: (_) => const AttendanceCorrectionScreen()),
                                                                                      );
                                                      },
                                                      icon: const Icon(Icons.edit_calendar),
                                                      label: const Text('طلب تصحيح حضور (نسيت التسجيل؟)'),
                                                    ),
                                        const SizedBox(height: 24),
                                        const Text('سجل الحضور الأخير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 8),
                                        ..._history.map((r) => Card(
                                                          margin: const EdgeInsets.only(bottom: 8),
                                                          child: ListTile(
                                                                              leading: CircleAvatar(
                                                                                                    backgroundColor: const Color(0x1A009688),
                                                                                                    child: Icon(
                                                                                                                            r.checkOut == null ? Icons.play_circle_fill : Icons.check_circle,
                                                                                                                            color: Colors.teal,
                                                                                                                          ),
                                                                                                  ),
                                                                              title: Text(DateFormat('yyyy-MM-dd').format(r.checkIn.toLocal())),
                                                                              subtitle: Text(
                                                                                                    'دخول: ${DateFormat('HH:mm').format(r.checkIn.toLocal())}'
                                                                                                    '${r.checkOut != null ? '  •  خروج: ${DateFormat('HH:mm').format(r.checkOut!.toLocal())}' : '  •  مستمر'}',
                                                                                                  ),
                                                                              trailing: r.workedHours != null
                                                                                  ? Text('${r.workedHours!.toStringAsFixed(2)} س',
                                                                                                                   style: const TextStyle(fontWeight: FontWeight.bold))
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
