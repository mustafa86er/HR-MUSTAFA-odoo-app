import 'package:flutter/material.dart';

/// شاشة "حول التطبيق" - تعرّف بالتطبيق والمطوّر.
class AboutScreen extends StatelessWidget {
    const AboutScreen({super.key});

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(title: const Text('حول التطبيق')),
                  body: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                                        Center(
                                                      child: Container(
                                                                      width: 110,
                                                                      height: 110,
                                                                      decoration: BoxDecoration(
                                                                                        borderRadius: BorderRadius.circular(28),
                                                                                        gradient: const LinearGradient(
                                                                                                            begin: Alignment.topCenter,
                                                                                                            end: Alignment.bottomCenter,
                                                                                                            colors: [Color(0xFF1E4A8C), Color(0xFF102852)],
                                                                                                          ),
                                                                                      ),
                                                                      child: const Icon(Icons.badge, color: Colors.white, size: 56),
                                                                    ),
                                                    ),
                                        const SizedBox(height: 20),
                                        const Center(
                                                      child: Text(
                                                                      'تطبيق HR الاجتهاد',
                                                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                                                      textAlign: TextAlign.center,
                                                                    ),
                                                    ),
                                        const SizedBox(height: 6),
                                        const Center(
                                                      child: Text(
                                                                      'تطبيق موارد بشرية متكامل (حضور، إجازات، رواتب، موافقات)\nمرتبط مباشرة بنظام Odoo',
                                                                      style: TextStyle(color: Colors.grey, height: 1.5),
                                                                      textAlign: TextAlign.center,
                                                                    ),
                                                    ),
                                        const SizedBox(height: 32),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        Card(
                                                      child: Padding(
                                                                      padding: const EdgeInsets.all(20),
                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: const [
                                                                                                            Icon(Icons.engineering, color: Color(0xFF1E4A8C), size: 36),
                                                                                                            SizedBox(height: 10),
                                                                                                            Text(
                                                                                                                                  'تم إنشاء هذا التطبيق بواسطة',
                                                                                                                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                                                                                                                ),
                                                                                                            SizedBox(height: 4),
                                                                                                            Text(
                                                                                                                                  'المهندس مصطفى ارخيص',
                                                                                                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                                                                                                ),
                                                                                                            SizedBox(height: 4),
                                                                                                            Text(
                                                                                                                                  'خبير أنظمة واستشارات Odoo',
                                                                                                                                  style: TextStyle(color: Color(0xFF1E4A8C), fontSize: 13),
                                                                                                                                ),
                                                                                                          ],
                                                                                      ),
                                                                    ),
                                                    ),
                                        const SizedBox(height: 20),
                                        const Center(
                                                      child: Text(
                                                                      'الإصدار 1.0.0',
                                                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                                                    ),
                                                    ),
                                      ],
                          ),
                );
    }
}
