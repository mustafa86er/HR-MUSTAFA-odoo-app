import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HrOdooApp());
}

class HrOdooApp extends StatelessWidget {
  const HrOdooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..tryAutoLogin(),
      child: MaterialApp(
        title: 'HR Odoo App',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          fontFamily: 'Cairo',
        ),
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    switch (app.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.loggedIn:
        return const HomeScreen();
      case AuthStatus.loggedOut:
        return const LoginScreen();
    }
  }
}
