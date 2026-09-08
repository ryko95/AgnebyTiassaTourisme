import '../../domain/energy_models.dart';

class EnergyAlert {
  const EnergyAlert({required this.title, required this.message, required this.level});

  final String title;
  final String message;
  final AlertLevel level;
}

enum AlertLevel { info, warning, critical }

class AlertEvaluator {
  const AlertEvaluator._();

  static List<EnergyAlert> evaluate(EnergySummary summary, AlertSettings settings) {
    final alerts = <EnergyAlert>[];
    if (summary.currentBalanceEstimateKwh <= settings.lowBalanceKwh) {
      alerts.add(EnergyAlert(
        title: 'Crédit énergie faible',
        message:
            'Solde estimé : ${summary.currentBalanceEstimateKwh.toStringAsFixed(1)} kWh. Seuil : ${settings.lowBalanceKwh.toStringAsFixed(1)} kWh.',
        level: AlertLevel.critical,
      ));
    }
    final autonomy = summary.autonomyDays;
    if (autonomy != null && autonomy <= settings.lowAutonomyDays) {
      alerts.add(EnergyAlert(
        title: 'Autonomie faible',
        message:
            'Au rythme actuel, il resterait environ ${autonomy.toStringAsFixed(1)} jour(s) d’énergie.',
        level: AlertLevel.warning,
      ));
    }
    if (summary.isHighConsumption(settings.highConsumptionRatio)) {
      alerts.add(const EnergyAlert(
        title: 'Hausse de consommation',
        message: 'La dernière période dépasse sensiblement votre consommation habituelle.',
        level: AlertLevel.warning,
      ));
    }
    return alerts;
  }
}
