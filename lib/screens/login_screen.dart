import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final _userCtrl = TextEditingController();
    final _passCtrl = TextEditingController();
    bool _obscure = true;

    Future<void> _submit(AppState app) async {
          FocusScope.of(context).unfocus();
          final ok = await app.login(_userCtrl.text.trim(), _passCtrl.text);
          if (ok && mounted) {
                  Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
          }
    }

    @override
    Widget build(BuildContext context) {
          final app = context.watch<AppState>();
          return Scaffold(
                  body: SafeArea(
                            child: Center(
                                        child: SingleChildScrollView(
                                                      padding: const EdgeInsets.all(24),
                                                      child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                                        Container(
                                                                                                            width: 96,
                                                                                                            height: 96,
                                                                                                            decoration: BoxDecoration(
                                                                                                                                  borderRadius: BorderRadius.circular(24),
                                                                                                                                  gradient: const LinearGradient(
                                                                                                                                                          begin: Alignment.topCenter,
                                                                                                                                                          end: Alignment.bottomCenter,
                                                                                                                                                          colors: [Color(0xFF1E4A8C), Color(0xFF102852)],
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                            child: const Icon(Icons.badge_outlined, size: 48, color: Colors.white),
                                                                                                          ),
                                                                                        const SizedBox(height: 16),
                                                                                        const Text(
                                                                                                            'HR الاجتهاد',
                                                                                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                                                                          ),
                                                                                        const Text(
                                                                                                            'تسجيل دخول موحّد بحساب Odoo',
                                                                                                            style: TextStyle(color: Colors.grey),
                                                                                                          ),
                                                                                        const SizedBox(height: 32),
                                                                                        TextField(
                                                                                                            controller: _userCtrl,
                                                                                                            decoration: const InputDecoration(
                                                                                                                                  labelText: 'البريد الإلكتروني / اسم المستخدم',
                                                                                                                                  prefixIcon: Icon(Icons.person_outline),
                                                                                                                                  border: OutlineInputBorder(),
                                                                                                                                ),
                                                                                                          ),
                                                                                        const SizedBox(height: 16),
                                                                                        TextField(
                                                                                                            controller: _passCtrl,
                                                                                                            obscureText: _obscure,
                                                                                                            onSubmitted: (_) => _submit(app),
                                                                                                            decoration: InputDecoration(
                                                                                                                                  labelText: 'كلمة المرور',
                                                                                                                                  prefixIcon: const Icon(Icons.lock_outline),
                                                                                                                                  border: const OutlineInputBorder(),
                                                                                                                                  suffixIcon: IconButton(
                                                                                                                                                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                                                                                                                                          onPressed: () => setState(() => _obscure = !_obscure),
                                                                                                                                                        ),
                                                                                                                                ),
                                                                                                          ),
                                                                                        if (app.lastError != null) ...[
                                                                                                            const SizedBox(height: 12),
                                                                                                            Text(app.lastError!, style: const TextStyle(color: Colors.red)),
                                                                                                          ],
                                                                                        const SizedBox(height: 24),
                                                                                        SizedBox(
                                                                                                            width: double.infinity,
                                                                                                            height: 48,
                                                                                                            child: ElevatedButton(
                                                                                                                                  onPressed: app.isLoading ? null : () => _submit(app),
                                                                                                                                  child: app.isLoading
                                                                                                                                      ? const SizedBox(
                                                                                                                                                                    height: 20,
                                                                                                                                                                    width: 20,
                                                                                                                                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                                                                                                                                  )
                                                                                                                                      : const Text('تسجيل الدخول'),
                                                                                                                                ),
                                                                                                          ),
                                                                                      ],
                                                                    ),
                                                    ),
                                      ),
                          ),
                );
    }
}
