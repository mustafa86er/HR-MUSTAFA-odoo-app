import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'attendance_correction_screen.dart';
import 'approvals_screen.dart';
import 'profile_screen.dart';
import 'contact_us_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';

/// شاشة "المزيد" - القائمة الشاملة (تصحيح حضور، تتبع وموافقات، تواصل معنا،
/// الملف الشخصي، حول التطبيق، تسجيل الخروج) بأسلوب مشابه للتطبيقات الاحترافية.
class MoreScreen extends StatelessWidget {
    const MoreScreen({super.key});

    @override
    Widget build(BuildContext context) {
          final app = context.watch<AppState>();
          final isManager = app.currentEmployee?.isManager ?? false;

          Widget tile({
                  required IconData icon,
                  required String title,
                  required VoidCallback onTap,
                  Color color = const Color(0xFF1E4A8C),
          }) {
                  return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                                        leading: CircleAvatar(
                                                      backgroundColor: color.withOpacity(0.12),
                                                      child: Icon(icon, color: color),
                                                    ),
                                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        trailing: const Icon(Icons.chevron_left),
                                        onTap: onTap,
                                      ),
                          );
          }

          return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                            tile(
                                        icon: Icons.edit_calendar,
                                        title: 'طلب تصحيح حضور',
                                        onTap: () => Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (_) => const AttendanceCorrectionScreen()),
                                                    ),
                                      ),
                            if (isManager)
                              tile(
                                            icon: Icons.fact_check_outlined,
                                            title: 'التتبع والموافقات',
                                            onTap: () => Navigator.of(context).push(
                                                            MaterialPageRoute(
                                                                              builder: (_) => Scaffold(
                                                                                                  appBar: AppBar(title: const Text('التتبع والموافقات')),
                                                                                                  body: const ApprovalsScreen(),
                                                                                                ),
                                                                            ),
                                                          ),
                                          ),
                            tile(
                                        icon: Icons.person_outline,
                                        title: 'الملف الشخصي',
                                        onTap: () => Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                                    ),
                                      ),
                            tile(
                                        icon: Icons.support_agent,
                                        title: 'تواصل معنا',
                                        onTap: () => Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                                                    ),
                                      ),
                            tile(
                                        icon: Icons.info_outline,
                                        title: 'حول التطبيق',
                                        onTap: () => Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                                                    ),
                                      ),
                            tile(
                                        icon: Icons.logout,
                                        color: Colors.red,
                                        title: 'تسجيل الخروج',
                                        onTap: () async {
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
                );
    }
}
