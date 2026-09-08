import 'energy_models.dart';

abstract class EnergyRepository {
  Future<List<Meter>> listMeters();
  Future<Meter> createMeter({
    required String name,
    required String meterNumber,
    String? locationLabel,
  });

  Future<List<MeterReading>> listReadings(String meterId);
  Future<void> addReading(MeterReading reading);

  Future<List<Recharge>> listRecharges(String meterId);
  Future<void> addRecharge(Recharge recharge);

  Future<AlertSettings> getAlertSettings(String meterId);
  Future<void> saveAlertSettings(AlertSettings settings);
}
