import 'energy_models.dart';

/// Contrat volontairement abstrait pour brancher plus tard un backend de
/// paiement + vending CIE autorisé, sans modifier l'interface Flutter.
abstract class EnergyPurchaseGateway {
  Future<EnergyPurchaseResult> purchase({
    required String meterNumber,
    required int amountXof,
    required RechargeChannel channel,
  });
}

class EnergyPurchaseResult {
  const EnergyPurchaseResult({
    required this.transactionId,
    required this.status,
    this.energyKwh,
    this.token,
  });

  final String transactionId;
  final String status;
  final double? energyKwh;
  final String? token;
}

class VendingUnavailableException implements Exception {
  const VendingUnavailableException();

  @override
  String toString() =>
      'Le vending CIE n’est pas configuré. Un accès officiel au service est requis.';
}

class DisabledEnergyPurchaseGateway implements EnergyPurchaseGateway {
  const DisabledEnergyPurchaseGateway();

  @override
  Future<EnergyPurchaseResult> purchase({
    required String meterNumber,
    required int amountXof,
    required RechargeChannel channel,
  }) =>
      Future.error(const VendingUnavailableException());
}
