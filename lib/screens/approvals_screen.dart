import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/leave_service.dart';
import '../services/odoo_client.dart';

/// شاشة موافقات المدير: تعرض طلبات إجازة موظفيه المباشرين (parent_id) المنتظرة
/// وتسمح بالقبول أو الرفض مباشرة (يستدعي workflow الموافقة في Odoo نفسه).
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  final _service = LeaveService();
  List<LeaveRequest> _pending = [];
  bool _loading = true;
  String? _error;
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final managerId = context.read<AppState>().currentEmployee!.employeeId;
    setState(() => _loading = true);
    try {
      final pending = await _service.getPendingApprovals(managerId);
      setState(() {
        _pending = pending;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is OdooException ? e.message : e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _act(LeaveRequest leave, bool approve) async {
    setState(() => _busyIds.add(leave.id));
    try {
      if (approve) {
        await _service.approve(leave.id);
      } else {
        await _service.refuse(leave.id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is OdooException ? e.message : e.toString())),
        );
      }
    } finally {
      setState(() => _busyIds.remove(leave.id));
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
          if (_pending.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد طلبات بانتظار موافقتك 🎉')),
            ),
          ..._pending.map((l) {
            final busy = _busyIds.contains(l.id);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${l.leaveTypeName} — ${l.numberOfDays} يوم'),
                    Text(
                      '${DateFormat('yyyy-MM-dd').format(l.dateFrom)} → ${DateFormat('yyyy-MM-dd').format(l.dateTo)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (l.description != null && l.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.description!, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : () => _act(l, false),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('رفض', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: busy ? null : () => _act(l, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            icon: busy
                                ? const SizedBox(
                                    height: 16, width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check),
                            label: const Text('قبول'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
