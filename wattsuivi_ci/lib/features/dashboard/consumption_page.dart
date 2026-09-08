import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/utils/formatters.dart';

class ConsumptionPage extends StatelessWidget {
  const ConsumptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.summary;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Analyse détaillée', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(controller.selectedMeter?.name ?? 'Aucun compteur'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.query_stats, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Consommation moyenne'),
                        Text('${summary.averageKwhPerDay.toStringAsFixed(2)} kWh/jour', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Périodes calculées', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (summary.segments.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Ajoutez au moins deux relevés pour calculer une consommation.')))
          else
            ...summary.segments.reversed.map(
              (segment) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.bolt_outlined)),
                  title: Text('${segment.averageKwhPerDay.toStringAsFixed(2)} kWh/jour'),
                  subtitle: Text(
                    '${formatDate(segment.start.capturedAt)} → ${formatDate(segment.end.capturedAt)}\n'
                    '${segment.consumedKwh.toStringAsFixed(1)} kWh consommés • ${segment.rechargedKwh.toStringAsFixed(1)} kWh rechargés',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Derniers relevés', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...controller.readings.reversed.take(10).map(
                (reading) => Card(
                  child: ListTile(
                    leading: Icon(reading.source.name == 'scan' ? Icons.document_scanner_outlined : Icons.edit_note),
                    title: Text('${reading.balanceKwh.toStringAsFixed(2)} kWh'),
                    subtitle: Text(formatDateTime(reading.capturedAt)),
                    trailing: Text(reading.source.name == 'scan' ? 'Scan' : 'Manuel'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
