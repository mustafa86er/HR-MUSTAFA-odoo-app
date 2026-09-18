import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/leave_service.dart';
import '../services/approval_service.dart';
import '../services/odoo_client.dart';

/// شاشة موافقات المدير: تعرض طلبات إجازة موظفيه المباشرين وطلبات تصحيح
/// الحضور المنتظرة، وتسمح بالقبول أو الرفض مباشرة (يستدعي workflow أودو نفسه).
class ApprovalsScreen extends StatefulWidget {
    const ApprovalsScreen({super.key});

    @override
    State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> with SingleTickerProviderStateMixin {
    late final TabController _tab = TabController(length: 2, vsync: this);
    final _leaveService = LeaveService();
    final _approvalService = ApprovalService();

    List<LeaveRequest> _pendingLeaves = [];
    List<ApprovalRequest> _pendingCorrections = [];
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
                  final leaves = await _leaveService.getPendingApprovals(managerId);
                  List<ApprovalRequest> corrections = [];
                  try {
                            corrections = await _approvalService.getPendingApprovals();
                  } catch (_) {
                            // تجاهل إن لم تكن فئة تصحيح الحضور مهيأة بعد في Odoo
                  }
                  setState(() {
                            _pendingLeaves = leaves;
                            _pendingCorrections = corrections;
                            _error = null;
                  });
          } catch (e) {
                  setState(() => _error = e is OdooException ? e.message : e.toString());
          } finally {
                  setState(() => _loading = false);
          }
    }

    Future<void> _actLeave(LeaveRequest leave, bool approve) async {
          setState(() => _busyIds.add(leave.id));
          try {
                  if (approve) {
                            await _leaveService.approve(leave.id);
                  } else {
                            await _leaveService.refuse(leave.id);
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

    Future<void> _actCorrection(ApprovalRequest req, bool approve) async {
          setState(() => _busyIds.add(req.id));
          try {
                  if (approve) {
                            await _approvalService.approve(req.id);
                  } else {
                            await _approvalService.refuse(req.id);
                  }
                  await _load();
          } catch (e) {
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e is OdooException ? e.message : e.toString())),
                                      );
                  }
          } finally {
                  setState(() => _busyIds.remove(req.id));
          }
    }

    @override
    Widget build(BuildContext context) {
          return Column(
                  children: [
                            TabBar(
                                        controller: _tab,
                                        tabs: [
                                                      Tab(text: 'إجازات (${_pendingLeaves.length})'),
                                                      Tab(text: 'تصحيح حضور (${_pendingCorrections.length})'),
                                                    ],
                                      ),
                            if (_loading)
                              const Expanded(child: Center(child: CircularProgressIndicator()))
                            else
                              Expanded(
                                            child: TabBarView(
                                                            controller: _tab,
                                                            children: [
                                                                              _buildLeavesTab(),
                                                                              _buildCorrectionsTab(),
                                                                            ],
                                                          ),
                                          ),
                          ],
                );
    }

    Widget _buildLeavesTab() {
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
                                        if (_pendingLeaves.isEmpty && _error == null)
                                          const Padding(
                                                          padding: EdgeInsets.all(24),
                                                          child: Center(child: Text('لا توجد طلبات إجازة بانتظار موافقتك 🎉')),
                                                        ),
                                        ..._pendingLeaves.map((l) {
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
                                                                                                                                                                                                                                              onPressed: busy ? null : () => _actLeave(l, false),
                                                                                                                                                                                                                                              icon: const Icon(Icons.close, color: Colors.red),
                                                                                                                                                                                                                                              label: const Text('رفض', style: TextStyle(color: Colors.red)),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                              ),
                                                                                                                                                                                    const SizedBox(width: 8),
                                                                                                                                                                                    Expanded(
                                                                                                                                                                                                                child: ElevatedButton.icon(
                                                                                                                                                                                                                                              onPressed: busy ? null : () => _actLeave(l, true),
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

    Widget _buildCorrectionsTab() {
          return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                                        if (_pendingCorrections.isEmpty)
                                          const Padding(
                                                          padding: EdgeInsets.all(24),
                                                          child: Center(child: Text('لا توجد طلبات تصحيح حضور بانتظار موافقتك 🎉')),
                                                        ),
                                        ..._pendingCorrections.map((r) {
                                                      final busy = _busyIds.contains(r.id);
                                                      return Card(
                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.all(12),
                                                                                        child: Column(
                                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                            children: [
                                                                                                                                  Text(r.requestOwnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                                                                                  const SizedBox(height: 4),
                                                                                                                                  Text(r.name),
                                                                                                                                  if (r.dateStart != null)
                                                                                                                                    Text(
                                                                                                                                                              DateFormat('yyyy-MM-dd HH:mm').format(r.dateStart!),
                                                                                                                                                              style: const TextStyle(color: Colors.grey),
                                                                                                                                                            ),
                                                                                                                                  if (r.reason != null && r.reason!.isNotEmpty)
                                                                                                                                    Padding(
                                                                                                                                                              padding: const EdgeInsets.only(top: 4),
                                                                                                                                                              child: Text(r.reason!, style: const TextStyle(fontStyle: FontStyle.italic)),
                                                                                                                                                            ),
                                                                                                                                  const SizedBox(height: 12),
                                                                                                                                  Row(
                                                                                                                                                          children: [
                                                                                                                                                                                    Expanded(
                                                                                                                                                                                                                child: OutlinedButton.icon(
                                                                                                                                                                                                                                              onPressed: busy ? null : () => _actCorrection(r, false),
                                                                                                                                                                                                                                              icon: const Icon(Icons.close, color: Colors.red),
                                                                                                                                                                                                                                              label: const Text('رفض', style: TextStyle(color: Colors.red)),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                              ),
                                                                                                                                                                                    const SizedBox(width: 8),
                                                                                                                                                                                    Expanded(
                                                                                                                                                                                                                child: ElevatedButton.icon(
                                                                                                                                                                                                                                              onPressed: busy ? null : () => _actCorrection(r, true),
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
