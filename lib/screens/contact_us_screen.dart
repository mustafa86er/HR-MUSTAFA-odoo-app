import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/odoo_client.dart';

/// شاشة "تواصل معنا" - ترسل رسالة الموظف كملاحظة على سجله في Odoo (Chatter)
/// بحيث يراها المسؤول عن الموارد البشرية مباشرة من نظام أودو.
class ContactUsScreen extends StatefulWidget {
    const ContactUsScreen({super.key});

    @override
    State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
    final _messageController = TextEditingController();
    String _type = 'دعم فني';
    bool _sending = false;

    @override
    void dispose() {
          _messageController.dispose();
          super.dispose();
    }

    Future<void> _send() async {
          if (_messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة رسالتك أولاً')),
                          );
                  return;
          }
          final employeeId = context.read<AppState>().currentEmployee!.employeeId;
          setState(() => _sending = true);
          try {
                  await OdooClient.instance.executeKw(
                            'hr.employee',
                            'message_post',
                            [
                                        [employeeId]
                                      ],
                            kwargs: {
                                        'body': '[$_type] ${_messageController.text.trim()}',
                            },
                          );
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم إرسال رسالتك بنجاح')),
                                      );
                            Navigator.of(context).pop();
                  }
          } catch (e) {
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e is OdooException ? e.message : e.toString())),
                                      );
                  }
          } finally {
                  if (mounted) setState(() => _sending = false);
          }
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(title: const Text('تواصل معنا')),
                  body: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                                        const Text(
                                                      'أرسل استفسارك أو مشكلتك وستصل مباشرة إلى قسم الموارد البشرية عبر نظام Odoo.',
                                                      style: TextStyle(color: Colors.grey),
                                                    ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                                      spacing: 8,
                                                      children: ['دعم فني', 'استفسار', 'شكوى'].map((t) {
                                                                      final selected = _type == t;
                                                                      return ChoiceChip(
                                                                                        label: Text(t),
                                                                                        selected: selected,
                                                                                        onSelected: (_) => setState(() => _type = t),
                                                                                      );
                                                      }).toList(),
                                                    ),
                                        const SizedBox(height: 16),
                                        TextField(
                                                      controller: _messageController,
                                                      maxLines: 5,
                                                      decoration: const InputDecoration(
                                                                      labelText: 'رسالتك',
                                                                      border: OutlineInputBorder(),
                                                                    ),
                                                    ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                                      height: 50,
                                                      child: ElevatedButton.icon(
                                                                      onPressed: _sending ? null : _send,
                                                                      icon: _sending
                                                                          ? const SizedBox(
                                                                                                  height: 18, width: 18,
                                                                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                                          : const Icon(Icons.send),
                                                                      label: const Text('إرسال'),
                                                                    ),
                                                    ),
                                      ],
                          ),
                );
    }
}
