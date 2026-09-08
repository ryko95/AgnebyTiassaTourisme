import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_scope.dart';
import '../../core/config/app_config.dart';
import '../../domain/energy_models.dart';
import '../meters/add_meter_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _editAlerts() async {
    final controller = AppScope.of(context);
    final current = controller.alertSettings;
    if (current == null) return;

    final balance = TextEditingController(text: current.lowBalanceKwh.toStringAsFixed(1));
    final autonomy = TextEditingController(text: current.lowAutonomyDays.toStringAsFixed(1));
    var enabled = current.notificationsEnabled;

    final result = await showDialog<AlertSettings>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Seuils d’alerte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: balance,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Alerte solde faible', suffixText: 'kWh'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: autonomy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Alerte autonomie', suffixText: 'jours'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications activées'),
                value: enabled,
                onChanged: (value) => setDialogState(() => enabled = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final lowBalance = double.tryParse(balance.text.replaceAll(',', '.'));
                final lowAutonomy = double.tryParse(autonomy.text.replaceAll(',', '.'));
                if (lowBalance == null || lowBalance < 0 || lowAutonomy == null || lowAutonomy < 0) return;
                Navigator.pop(
                  dialogContext,
                  current.copyWith(
                    lowBalanceKwh: lowBalance,
                    lowAutonomyDays: lowAutonomy,
                    notificationsEnabled: enabled,
                  ),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    balance.dispose();
    autonomy.dispose();
    if (result != null && mounted) {
      await controller.saveSettings(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Paramètres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.electric_meter_outlined),
                  title: const Text('Mes compteurs'),
                  subtitle: Text('${controller.meters.length} compteur(s)'),
                  trailing: const Icon(Icons.add),
                  onTap: () => showDialog(context: context, builder: (_) => const AddMeterDialog()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Alertes et notifications'),
                  subtitle: controller.alertSettings == null
                      ? const Text('Ajoutez un compteur pour configurer les alertes.')
                      : Text(
                          'Solde ≤ ${controller.alertSettings!.lowBalanceKwh.toStringAsFixed(1)} kWh • autonomie ≤ ${controller.alertSettings!.lowAutonomyDays.toStringAsFixed(1)} jours',
                        ),
                  onTap: controller.alertSettings == null ? null : _editAlerts,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Mode de données'),
              subtitle: Text(AppConfig.modeLabel),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Sécurité des recharges'),
              subtitle: Text('WattSuivi CI ne stocke par défaut que les 4 derniers chiffres d’un token. La génération officielle de token restera désactivée tant qu’aucune API/vending CIE autorisée n’est disponible.'),
            ),
          ),
          if (AppConfig.cloudEnabled) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
          const SizedBox(height: 24),
          Text('WattSuivi CI • MVP scalable', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
