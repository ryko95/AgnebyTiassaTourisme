import 'package:flutter/material.dart';

import '../features/dashboard/consumption_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/readings/reading_page.dart';
import '../features/recharges/recharge_page.dart';
import '../features/settings/settings_page.dart';
import 'app_scope.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _index = 0;

  static const _pages = [
    DashboardPage(),
    ConsumptionPage(),
    ReadingPage(),
    RechargePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded),
            SizedBox(width: 6),
            Text('WattSuivi CI'),
          ],
        ),
        actions: [
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: controller.errorMessage != null
          ? _ErrorView(message: controller.errorMessage!, onRetry: controller.initialize)
          : IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Analyse'),
          NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), label: 'Relevé'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Recharge'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Réglages'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
