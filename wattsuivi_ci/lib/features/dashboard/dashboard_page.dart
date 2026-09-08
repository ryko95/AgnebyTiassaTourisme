import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/alert_evaluator.dart';
import '../../core/utils/formatters.dart';
import '../../domain/energy_models.dart';
import '../meters/add_meter_dialog.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final meter = controller.selectedMeter;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.initialize,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _MeterSelector(
              meters: controller.meters,
              selected: meter,
              onChanged: (value) {
                if (value != null) controller.selectMeter(value);
              },
            ),
            const SizedBox(height: 16),
            if (meter == null)
              _EmptyMeter(onAdd: () => showDialog(context: context, builder: (_) => const AddMeterDialog()))
            else ...[
              _HeroBalance(summary: controller.summary),
              const SizedBox(height: 14),
              _KpiGrid(summary: controller.summary),
              const SizedBox(height: 14),
              _MiniChart(summary: controller.summary),
              if (controller.alerts.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Alertes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...controller.alerts.map((alert) => _AlertCard(alert: alert)),
              ],
              if (controller.summary.dataWarnings.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...controller.summary.dataWarnings.map(
                  (warning) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Qualité des données'),
                      subtitle: Text(warning),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MeterSelector extends StatelessWidget {
  const _MeterSelector({required this.meters, required this.selected, required this.onChanged});
  final List<Meter> meters;
  final Meter? selected;
  final ValueChanged<Meter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Meter>(
            key: ValueKey(selected?.id),
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Compteur', prefixIcon: Icon(Icons.electric_meter_outlined)),
            items: meters
                .map((meter) => DropdownMenuItem(value: meter, child: Text(meter.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Ajouter un compteur',
          onPressed: () => showDialog(context: context, builder: (_) => const AddMeterDialog()),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _HeroBalance extends StatelessWidget {
  const _HeroBalance({required this.summary});
  final EnergySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              child: const Icon(Icons.bolt_rounded, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde estimé actuel'),
                  Text(
                    '${summary.currentBalanceEstimateKwh.toStringAsFixed(1)} kWh',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (summary.estimatedDepletionAt != null)
                    Text('Épuisement estimé : ${formatDate(summary.estimatedDepletionAt!)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});
  final EnergySummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Moyenne / jour', '${summary.averageKwhPerDay.toStringAsFixed(2)} kWh', Icons.speed),
      ('Autonomie', summary.autonomyDays == null ? '—' : '${summary.autonomyDays!.toStringAsFixed(1)} j', Icons.timelapse),
      ('Consommation calculée', '${summary.totalConsumedKwh.toStringAsFixed(1)} kWh', Icons.analytics_outlined),
      ('Périodes analysées', '${summary.segments.length}', Icons.date_range_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3),
                          const SizedBox(height: 10),
                          Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 3),
                          Text(item.$2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.summary});
  final EnergySummary summary;

  @override
  Widget build(BuildContext context) {
    final spots = summary.segments.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.averageKwhPerDay)).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Évolution de la consommation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Moyenne quotidienne entre deux relevés'),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: spots.isEmpty
                  ? const Center(child: Text('Deux relevés minimum sont nécessaires.'))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 3,
                            color: Theme.of(context).colorScheme.secondary,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(.45)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final EnergyAlert alert;

  @override
  Widget build(BuildContext context) {
    final icon = switch (alert.level) {
      AlertLevel.info => Icons.info_outline,
      AlertLevel.warning => Icons.warning_amber_rounded,
      AlertLevel.critical => Icons.error_outline,
    };
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(alert.title), subtitle: Text(alert.message)),
    );
  }
}

class _EmptyMeter extends StatelessWidget {
  const _EmptyMeter({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.electric_meter_outlined, size: 54),
            const SizedBox(height: 12),
            const Text('Aucun compteur enregistré.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Ajouter mon premier compteur')),
          ],
        ),
      ),
    );
  }
}
