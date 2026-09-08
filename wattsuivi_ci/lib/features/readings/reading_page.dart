import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/meter_ocr_service.dart';
import '../../domain/energy_models.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final _manualValue = TextEditingController();
  final _ocrService = MeterOcrService();
  bool _saving = false;
  bool _scanning = false;

  @override
  void dispose() {
    _manualValue.dispose();
    super.dispose();
  }

  Future<void> _saveManual() async {
    final raw = _manualValue.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < 0) {
      _message('Saisissez une valeur kWh valide.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AppScope.of(context).addReading(
        balanceKwh: value,
        source: ReadingSource.manual,
      );
      _manualValue.clear();
      _message('Relevé enregistré.');
    } catch (error) {
      _message('Erreur : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scan() async {
    if (AppScope.of(context).selectedMeter == null) {
      _message('Ajoutez d’abord un compteur.');
      return;
    }
    setState(() => _scanning = true);
    try {
      final result = await _ocrService.scanFromCamera();
      if (!mounted || result == null) return;
      final controller = TextEditingController(text: result.valueKwh.toStringAsFixed(2));
      final confirmed = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmer le relevé détecté'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vérifiez toujours la valeur lue sur l’écran du compteur.'),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Solde détecté (kWh)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                if (value != null && value >= 0) Navigator.pop(dialogContext, value);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (confirmed == null || !mounted) return;
      await AppScope.of(context).addReading(
        balanceKwh: confirmed,
        source: ReadingSource.scan,
        photoPath: result.imagePath,
        rawOcrText: result.rawText,
      );
      _message('Relevé scanné et enregistré.');
    } on FormatException catch (error) {
      _message(error.message);
    } catch (error) {
      _message('Scan impossible : $error');
    } finally {
      if (mounted) setState(() => _scanning = false);
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
          Text('Nouveau relevé', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(meter == null ? 'Aucun compteur sélectionné' : '${meter.name} • ${meter.meterNumber}'),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 30),
                      const SizedBox(width: 10),
                      Text('Saisie manuelle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _manualValue,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Solde affiché par le compteur',
                      suffixText: 'kWh',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: meter == null || _saving ? null : _saveManual,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le relevé'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.document_scanner_outlined, size: 30),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Scanner l’écran du compteur', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('L’OCR détecte une valeur probable en kWh puis vous demande de la confirmer avant sauvegarde.'),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: meter == null || _scanning ? null : _scan,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_scanning ? 'Analyse en cours…' : 'Ouvrir la caméra'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Conseil'),
              subtitle: Text('Effectuez les relevés à des heures proches et régulièrement pour améliorer la précision de la consommation moyenne.'),
            ),
          ),
        ],
      ),
    );
  }
}
