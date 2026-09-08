import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/energy_models.dart';
import '../domain/energy_repository.dart';

class LocalEnergyRepository implements EnergyRepository {
  LocalEnergyRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  final _uuid = const Uuid();

  static const _metersKey = 'wattsuivi.meters.v1';
  static const _readingsKey = 'wattsuivi.readings.v1';
  static const _rechargesKey = 'wattsuivi.recharges.v1';
  static const _settingsKey = 'wattsuivi.settings.v1';

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> data) =>
      _preferences.setString(key, jsonEncode(data));

  Future<void> ensureSeeded() async {
    final meters = await listMeters();
    if (meters.isNotEmpty) return;

    final now = DateTime.now();
    final home = Meter(
      id: _uuid.v4(),
      name: 'Maison Bouaké',
      meterNumber: '0425870001',
      locationLabel: 'Bouaké',
      createdAt: now.subtract(const Duration(days: 30)),
    );
    final office = Meter(
      id: _uuid.v4(),
      name: 'Bureau',
      meterNumber: '0425870002',
      locationLabel: 'Bouaké',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    await _writeList(_metersKey, [home.toJson(), office.toJson()]);

    final readings = <MeterReading>[
      MeterReading(
        id: _uuid.v4(),
        meterId: home.id,
        capturedAt: now.subtract(const Duration(days: 6)),
        balanceKwh: 45,
        source: ReadingSource.manual,
      ),
      MeterReading(
        id: _uuid.v4(),
        meterId: home.id,
        capturedAt: now.subtract(const Duration(days: 1)),
        balanceKwh: 50,
        source: ReadingSource.manual,
      ),
      MeterReading(
        id: _uuid.v4(),
        meterId: office.id,
        capturedAt: now.subtract(const Duration(days: 5)),
        balanceKwh: 25,
        source: ReadingSource.manual,
      ),
      MeterReading(
        id: _uuid.v4(),
        meterId: office.id,
        capturedAt: now.subtract(const Duration(days: 1)),
        balanceKwh: 17,
        source: ReadingSource.manual,
      ),
    ];
    await _writeList(_readingsKey, readings.map((e) => e.toJson()).toList());

    final recharge = Recharge(
      id: _uuid.v4(),
      meterId: home.id,
      rechargedAt: now.subtract(const Duration(days: 4)),
      amountXof: 10000,
      energyKwh: 30,
      channel: RechargeChannel.wave,
      reference: 'DEMO-001',
    );
    await _writeList(_rechargesKey, [recharge.toJson()]);

    final settings = [
      AlertSettings(meterId: home.id).toJson(),
      AlertSettings(meterId: office.id).toJson(),
    ];
    await _writeList(_settingsKey, settings);
  }

  @override
  Future<List<Meter>> listMeters() async {
    final raw = await _readList(_metersKey);
    final meters = raw.map(Meter.fromJson).where((m) => m.isActive).toList();
    meters.sort((a, b) => a.name.compareTo(b.name));
    return meters;
  }

  @override
  Future<Meter> createMeter({
    required String name,
    required String meterNumber,
    String? locationLabel,
  }) async {
    final all = await _readList(_metersKey);
    final meter = Meter(
      id: _uuid.v4(),
      name: name.trim(),
      meterNumber: meterNumber.trim(),
      locationLabel: locationLabel?.trim().isEmpty == true ? null : locationLabel?.trim(),
      createdAt: DateTime.now(),
    );
    all.add(meter.toJson());
    await _writeList(_metersKey, all);

    final settings = await _readList(_settingsKey);
    settings.add(AlertSettings(meterId: meter.id).toJson());
    await _writeList(_settingsKey, settings);
    return meter;
  }

  @override
  Future<List<MeterReading>> listReadings(String meterId) async {
    final raw = await _readList(_readingsKey);
    final readings = raw
        .map(MeterReading.fromJson)
        .where((reading) => reading.meterId == meterId)
        .toList();
    readings.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return readings;
  }

  @override
  Future<void> addReading(MeterReading reading) async {
    final all = await _readList(_readingsKey);
    all.add(reading.toJson());
    await _writeList(_readingsKey, all);
  }

  @override
  Future<List<Recharge>> listRecharges(String meterId) async {
    final raw = await _readList(_rechargesKey);
    final items = raw
        .map(Recharge.fromJson)
        .where((recharge) => recharge.meterId == meterId)
        .toList();
    items.sort((a, b) => a.rechargedAt.compareTo(b.rechargedAt));
    return items;
  }

  @override
  Future<void> addRecharge(Recharge recharge) async {
    final all = await _readList(_rechargesKey);
    all.add(recharge.toJson());
    await _writeList(_rechargesKey, all);
  }

  @override
  Future<AlertSettings> getAlertSettings(String meterId) async {
    final raw = await _readList(_settingsKey);
    for (final item in raw) {
      if (item['meter_id'] == meterId) return AlertSettings.fromJson(item);
    }
    return AlertSettings(meterId: meterId);
  }

  @override
  Future<void> saveAlertSettings(AlertSettings settings) async {
    final raw = await _readList(_settingsKey);
    raw.removeWhere((item) => item['meter_id'] == settings.meterId);
    raw.add(settings.toJson());
    await _writeList(_settingsKey, raw);
  }
}
