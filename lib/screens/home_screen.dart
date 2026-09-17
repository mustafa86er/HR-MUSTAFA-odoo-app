import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'attendance_screen.dart';
import 'leave_screen.dart';
import 'payslip_screen.dart';
import 'approvals_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isManager = app.currentEmployee?.isManager ?? false;

    final pages = <Widget>[
      const AttendanceScreen(),
      const LeaveScreen(),
      const PayslipScreen(),
      if (isManager) const ApprovalsScreen(),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.fingerprint), label: 'الحضور'),
      const NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'الإجازات'),
      const NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'الرواتب'),
      if (isManager)
        const NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'الموافقات'),
    ];

    if (_index >= pages.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.currentEmployee?.name ?? 'الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await app.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
