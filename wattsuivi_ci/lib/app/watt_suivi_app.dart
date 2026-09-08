import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../data/local_energy_repository.dart';
import '../data/supabase_energy_repository.dart';
import '../domain/energy_repository.dart';
import '../features/auth/auth_page.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'main_shell.dart';

class WattSuiviApp extends StatelessWidget {
  const WattSuiviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WattSuivi CI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.cloudEnabled) {
      return _AppSession(
        key: const ValueKey('local-session'),
        repository: LocalEnergyRepository(),
      );
    }

    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;
        if (session == null) return const AuthPage();
        return _AppSession(
          key: ValueKey(session.user.id),
          repository: SupabaseEnergyRepository(client),
        );
      },
    );
  }
}

class _AppSession extends StatefulWidget {
  const _AppSession({required this.repository, super.key});
  final EnergyRepository repository;

  @override
  State<_AppSession> createState() => _AppSessionState();
}

class _AppSessionState extends State<_AppSession> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(repository: widget.repository);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(controller: _controller, child: const MainShell());
  }
}
