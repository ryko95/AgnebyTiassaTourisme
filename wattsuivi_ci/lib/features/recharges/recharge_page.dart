import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/utils/formatters.dart';
import '../../domain/energy_models.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final _amount = TextEditingController();
  final _kwh = TextEditingController();
  final _reference = TextEditingController();
  final _tokenLast4 = TextEditingController();
  RechargeChannel _channel = RechargeChannel.wave;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _kwh.dispose();
    _reference.dispose();
    _tokenLast4.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\s'), ''));
    final kwh = _kwh.text.trim().isEmpty ? null : double.tryParse(_kwh.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _message('Saisissez un montant valide.');
      return;
    }
    if (_kwh.text.trim().isNotEmpty && (kwh == null || kwh <= 0)) {
      _message('La quantité de kWh est invalide.');
      return;
    }
    if (_tokenLast4.text.isNotEmpty && _tokenLast4.text.length != 4) {
      _message('Conservez seulement les 4 derniers chiffres du token.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.of(context).addRecharge(
        amountXof: amount,
        channel: _channel,
        energyKwh: kwh,
        reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        tokenLast4: _tokenLast4.text.trim().isEmpty ? null : _tokenLast4.text.trim(),
      );
      _amount.clear();
      _kwh.clear();
      _reference.clear();
      _tokenLast4.clear();
      _message('Recharge enregistrée dans l’historique.');
    } catch (error) {
      _message('Erreur : $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final meter = controller.selectedMeter;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Recharge', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Enregistrez ici une recharge déjà effectuée par un canal officiel.'),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cette version ne génère pas de token CIE et ne prélève pas d’argent. Elle assure le suivi des recharges effectuées via Orange Money, MTN MoMo, Moov Money, Wave, agence ou autre canal.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<RechargeChannel>(
                    initialValue: _channel,
                    decoration: const InputDecoration(labelText: 'Canal de recharge'),
                    items: RechargeChannel.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                    onChanged: (value) => setState(() => _channel = value ?? _channel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Montant payé', suffixText: 'FCFA'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _kwh,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Énergie reçue', suffixText: 'kWh'),
                  ),
                  const SizedBox(height: 6),
                  const Text('La quantité de kWh est fortement recommandée : elle est nécessaire pour calculer correctement la consommation entre deux relevés.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reference,
                    decoration: const InputDecoration(labelText: 'Référence transaction (facultatif)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenLast4,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '4 derniers chiffres du token (facultatif)'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: meter == null || _busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_busy ? 'Enregistrement…' : 'Enregistrer la recharge'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Historique', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (controller.recharges.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Aucune recharge enregistrée.')))
          else
            ...controller.recharges.reversed.take(20).map(
              (recharge) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.bolt)),
                  title: Text(formatXof(recharge.amountXof)),
                  subtitle: Text('${recharge.channel.label} • ${formatDateTime(recharge.rechargedAt)}'),
                  trailing: Text(recharge.energyKwh == null ? 'kWh ?' : '${recharge.energyKwh!.toStringAsFixed(1)} kWh'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
