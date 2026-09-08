import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/alert_evaluator.dart';
import '../core/services/notification_service.dart';
import '../data/local_energy_repository.dart';
import '../domain/energy_models.dart';
import '../domain/energy_repository.dart';

class AppController extends ChangeNotifier {
  AppController({required EnergyRepository repository}) : _repository = repository;

  final EnergyRepository _repository;
  final _uuid = const Uuid();

  List<Meter> meters = [];
  Meter? selectedMeter;
  List<MeterReading> readings = [];
  List<Recharge> recharges = [];
  AlertSettings? alertSettings;
  EnergySummary summary = const EnergySummary(
    segments: [],
    currentBalanceEstimateKwh: 0,
    averageKwhPerDay: 0,
    totalConsumedKwh: 0,
    dataWarnings: [],
  );
  List<EnergyAlert> alerts = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      if (_repository is LocalEnergyRepository) {
        await (_repository as LocalEnergyRepository).ensureSeeded();
      }
      meters = await _repository.listMeters();
      selectedMeter = meters.isEmpty ? null : meters.first;
      if (selectedMeter != null) await _loadSelectedData(notify: false);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMeter(Meter meter) async {
    selectedMeter = meter;
    isLoading = true;
    notifyListeners();
    try {
      await _loadSelectedData(notify: false);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedData({bool notify = true}) async {
    final meter = selectedMeter;
    if (meter == null) return;
    readings = await _repository.listReadings(meter.id);
    recharges = await _repository.listRecharges(meter.id);
    alertSettings = await _repository.getAlertSettings(meter.id);
    _recalculate();
    if (notify) notifyListeners();
  }

  void _recalculate() {
    summary = EnergyAnalytics.build(readings: readings, recharges: recharges);
    final settings = alertSettings;
    alerts = settings == null ? [] : AlertEvaluator.evaluate(summary, settings);
  }

  Future<void> createMeter({
    required String name,
    required String meterNumber,
    String? locationLabel,
  }) async {
    final meter = await _repository.createMeter(
      name: name,
      meterNumber: meterNumber,
      locationLabel: locationLabel,
    );
    meters = await _repository.listMeters();
    selectedMeter = meter;
    await _loadSelectedData(notify: false);
    notifyListeners();
  }

  Future<void> addReading({
    required double balanceKwh,
    required ReadingSource source,
    DateTime? capturedAt,
    String? photoPath,
    String? rawOcrText,
  }) async {
    final meter = selectedMeter;
    if (meter == null) throw StateError('Aucun compteur sélectionné.');
    final reading = MeterReading(
      id: _uuid.v4(),
      meterId: meter.id,
      capturedAt: capturedAt ?? DateTime.now(),
      balanceKwh: balanceKwh,
      source: source,
      photoPath: photoPath,
      rawOcrText: rawOcrText,
    );
    await _repository.addReading(reading);
    await _loadSelectedData(notify: false);
    notifyListeners();
    final settings = alertSettings;
    if (settings?.notificationsEnabled == true) {
      await NotificationService.instance.showAlerts(alerts);
    }
  }

  Future<void> addRecharge({
    required int amountXof,
    required RechargeChannel channel,
    double? energyKwh,
    DateTime? rechargedAt,
    String? reference,
    String? tokenLast4,
  }) async {
    final meter = selectedMeter;
    if (meter == null) throw StateError('Aucun compteur sélectionné.');
    final recharge = Recharge(
      id: _uuid.v4(),
      meterId: meter.id,
      rechargedAt: rechargedAt ?? DateTime.now(),
      amountXof: amountXof,
      channel: channel,
      energyKwh: energyKwh,
      reference: reference,
      tokenLast4: tokenLast4,
    );
    await _repository.addRecharge(recharge);
    await _loadSelectedData(notify: false);
    notifyListeners();
  }

  Future<void> saveSettings(AlertSettings settings) async {
    await _repository.saveAlertSettings(settings);
    alertSettings = settings;
    _recalculate();
    notifyListeners();
  }
}
