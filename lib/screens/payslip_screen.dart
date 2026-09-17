import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/payslip_service.dart';
import '../services/odoo_client.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final _service = PayslipService();
  List<Payslip> _payslips = [];
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
      final payslips = await _service.getMyPayslips(employeeId);
      setState(() {
        _payslips = payslips;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e is OdooException ? e.message : e.toString());
    } finally {
      setState(() => _loading = false);
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
                child: Text(
                  '$_error\n\nملاحظة: قد يتطلب هذا القسم تفعيل تطبيق الرواتب (Payroll) في Odoo وصلاحية القراءة عليه.',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          if (_payslips.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد كشوف رواتب بعد')),
            ),
          ..._payslips.map((p) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A009688),
                    child: Icon(Icons.receipt_long, color: Colors.teal),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    '${DateFormat('yyyy-MM-dd').format(p.dateFrom)} → ${DateFormat('yyyy-MM-dd').format(p.dateTo)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (p.netWage != null)
                        Text(
                          NumberFormat.currency(symbol: '', decimalDigits: 2).format(p.netWage),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text(p.stateLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
