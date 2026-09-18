import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/leave_service.dart';
import '../services/odoo_client.dart';

class LeaveScreen extends StatefulWidget {
    const LeaveScreen({super.key});

    @override
    State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
    final _service = LeaveService();
    List<LeaveRequest> _leaves = [];
    bool _loading = true;
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
                  final leaves = await _service.getMyLeaves(employeeId);
                  setState(() {
                            _leaves = leaves;
                            _error = null;
                  });
          } catch (e) {
                  setState(() => _error = e is OdooException ? e.message : e.toString());
          } finally {
                  setState(() => _loading = false);
          }
    }

    Color _stateColor(String state) {
          switch (state) {
            case 'validate':
                      return Colors.green;
            case 'refuse':
                      return Colors.red;
            case 'confirm':
            case 'validate1':
                      return Colors.orange;
            default:
                      return Colors.grey;
          }
    }

    Future<void> _openNewRequest() async {
          final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewLeaveRequestScreen()),
                );
          if (created == true) _load();
    }

    Map<String, double> get _usedByType {
          final map = <String, double>{};
          for (final l in _leaves) {
                  if (l.state != 'validate') continue;
                  map[l.leaveTypeName] = (map[l.leaveTypeName] ?? 0) + l.numberOfDays;
          }
          return map;
    }

    @override
    Widget build(BuildContext context) {
          final used = _usedByType;
          return Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                            onPressed: _openNewRequest,
                            icon: const Icon(Icons.add),
                            label: const Text('طلب إجازة'),
                          ),
                  body: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
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
                                                                            if (used.isNotEmpty) ...[
                                                                                                  const Text('ملخص الإجازات المستخدمة',
                                                                                                                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                                                                  const SizedBox(height: 10),
                                                                                                  SizedBox(
                                                                                                                          height: 90,
                                                                                                                          child: ListView.separated(
                                                                                                                                                    scrollDirection: Axis.horizontal,
                                                                                                                                                    itemCount: used.length,
                                                                                                                                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                                                                                                                                    itemBuilder: (_, i) {
                                                                                                                                                                                final entry = used.entries.elementAt(i);
                                                                                                                                                                                return Container(
                                                                                                                                                                                                              width: 140,
                                                                                                                                                                                                              padding: const EdgeInsets.all(12),
                                                                                                                                                                                                              decoration: BoxDecoration(
                                                                                                                                                                                                                                              color: const Color(0x1A1E4A8C),
                                                                                                                                                                                                                                              borderRadius: BorderRadius.circular(16),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                              child: Column(
                                                                                                                                                                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                                                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                                                                                                                                              children: [
                                                                                                                                                                                                                                                                                Text(entry.key,
                                                                                                                                                                                                                                                                                                                         maxLines: 1,
                                                                                                                                                                                                                                                                                                                         overflow: TextOverflow.ellipsis,
                                                                                                                                                                                                                                                                                                                         style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                                                                                                                                                                                                                                                const SizedBox(height: 6),
                                                                                                                                                                                                                                                                                Text('${entry.value.toStringAsFixed(1)} يوم',
                                                                                                                                                                                                                                                                                                                         style: const TextStyle(
                                                                                                                                                                                                                                                                                                                                                                   fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E4A8C))),
                                                                                                                                                                                                                                                                              ],
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                            );
                                                                                                                                                    },
                                                                                                                                                  ),
                                                                                                                        ),
                                                                                                  const SizedBox(height: 20),
                                                                                                ],
                                                                            if (_leaves.isEmpty && _error == null)
                                                                              const Padding(
                                                                                                      padding: EdgeInsets.all(24),
                                                                                                      child: Center(child: Text('لا توجد طلبات إجازة بعد')),
                                                                                                    ),
                                                                            ..._leaves.map((l) => Card(
                                                                                                      child: ListTile(
                                                                                                                                  leading: CircleAvatar(
                                                                                                                                                                backgroundColor: _stateColor(l.state).withOpacity(0.15),
                                                                                                                                                                child: Icon(Icons.event_note, color: _stateColor(l.state)),
                                                                                                                                                              ),
                                                                                                                                  title: Text(l.leaveTypeName),
                                                                                                                                  subtitle: Text(
                                                                                                                                                                '${DateFormat('yyyy-MM-dd').format(l.dateFrom)} → ${DateFormat('yyyy-MM-dd').format(l.dateTo)}\n'
                                                                                                                                                                '${l.numberOfDays} يوم',
                                                                                                                                                              ),
                                                                                                                                  isThreeLine: true,
                                                                                                                                  trailing: Chip(
                                                                                                                                                                label: Text(l.stateLabel, style: const TextStyle(fontSize: 11)),
                                                                                                                                                                backgroundColor: _stateColor(l.state).withOpacity(0.15),
                                                                                                                                                              ),
                                                                                                                                ),
                                                                                                    )),
                                                                          ],
                                                      ),
                                    ),
                );
    }
}

class NewLeaveRequestScreen extends StatefulWidget {
    const NewLeaveRequestScreen({super.key});

    @override
    State<NewLeaveRequestScreen> createState() => _NewLeaveRequestScreenState();
}

class _NewLeaveRequestScreenState extends State<NewLeaveRequestScreen> {
    final _service = LeaveService();
    final _reasonCtrl = TextEditingController();
    List<LeaveType> _types = [];
    LeaveType? _selectedType;
    DateTime? _from;
    DateTime? _to;
    bool _loadingTypes = true;
    bool _submitting = false;
    String? _error;

    @override
    void initState() {
          super.initState();
          _loadTypes();
    }

    Future<void> _loadTypes() async {
          try {
                  final types = await _service.getLeaveTypes();
                  setState(() {
                            _types = types;
                            _selectedType = types.isNotEmpty ? types.first : null;
                  });
          } catch (e) {
                  setState(() => _error = e is OdooException ? e.message : e.toString());
          } finally {
                  setState(() => _loadingTypes = false);
          }
    }

    Future<void> _pickDate(bool isFrom) async {
          final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
          if (picked != null) {
                  setState(() => isFrom ? _from = picked : _to = picked);
          }
    }

    Future<void> _submit() async {
          if (_selectedType == null || _from == null || _to == null) {
                  setState(() => _error = 'الرجاء إكمال جميع الحقول');
                  return;
          }
          final employeeId = context.read<AppState>().currentEmployee!.employeeId;
          setState(() {
                  _submitting = true;
                  _error = null;
          });
          try {
                  await _service.createLeaveRequest(
                            employeeId: employeeId,
                            leaveTypeId: _selectedType!.id,
                            dateFrom: _from!,
                            dateTo: _to!,
                            reason: _reasonCtrl.text.trim(),
                          );
                  if (mounted) Navigator.of(context).pop(true);
          } catch (e) {
                  setState(() => _error = e is OdooException ? e.message : e.toString());
          } finally {
                  setState(() => _submitting = false);
          }
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(title: const Text('طلب إجازة جديد')),
                  body: _loadingTypes
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: ListView(
                                                        children: [
                                                                            DropdownButtonFormField<LeaveType>(
                                                                                                  value: _selectedType,
                                                                                                  decoration: const InputDecoration(
                                                                                                                          labelText: 'نوع الإجازة',
                                                                                                                          border: OutlineInputBorder(),
                                                                                                                        ),
                                                                                                  items: _types
                                                                                                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                                                                                                      .toList(),
                                                                                                  onChanged: (v) => setState(() => _selectedType = v),
                                                                                                ),
                                                                            const SizedBox(height: 16),
                                                                            ListTile(
                                                                                                  contentPadding: EdgeInsets.zero,
                                                                                                  title: const Text('من تاريخ'),
                                                                                                  subtitle: Text(_from == null ? 'اختر تاريخًا' : DateFormat('yyyy-MM-dd').format(_from!)),
                                                                                                  trailing: const Icon(Icons.calendar_month),
                                                                                                  onTap: () => _pickDate(true),
                                                                                                ),
                                                                            ListTile(
                                                                                                  contentPadding: EdgeInsets.zero,
                                                                                                  title: const Text('إلى تاريخ'),
                                                                                                  subtitle: Text(_to == null ? 'اختر تاريخًا' : DateFormat('yyyy-MM-dd').format(_to!)),
                                                                                                  trailing: const Icon(Icons.calendar_month),
                                                                                                  onTap: () => _pickDate(false),
                                                                                                ),
                                                                            const SizedBox(height: 16),
                                                                            TextField(
                                                                                                  controller: _reasonCtrl,
                                                                                                  maxLines: 3,
                                                                                                  decoration: const InputDecoration(
                                                                                                                          labelText: 'السبب (اختياري)',
                                                                                                                          border: OutlineInputBorder(),
                                                                                                                        ),
                                                                                                ),
                                                                            if (_error != null) ...[
                                                                                                  const SizedBox(height: 12),
                                                                                                  Text(_error!, style: const TextStyle(color: Colors.red)),
                                                                                                ],
                                                                            const SizedBox(height: 24),
                                                                            SizedBox(
                                                                                                  height: 48,
                                                                                                  child: ElevatedButton(
                                                                                                                          onPressed: _submitting ? null : _submit,
                                                                                                                          child: _submitting
                                                                                                                              ? const SizedBox(
                                                                                                                                                              height: 20, width: 20,
                                                                                                                                                              child: CircularProgressIndicator(strokeWidth: 2))
                                                                                                                              : const Text('إرسال الطلب'),
                                                                                                                        ),
                                                                                                ),
                                                                          ],
                                                      ),
                                    ),
                );
    }
}
