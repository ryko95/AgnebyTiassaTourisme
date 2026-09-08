import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/energy_models.dart';
import '../domain/energy_repository.dart';

class SupabaseEnergyRepository implements EnergyRepository {
  SupabaseEnergyRepository(this._client);
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Utilisateur Supabase non connecté.');
    return id;
  }

  @override
  Future<List<Meter>> listMeters() async {
    final rows = await _client
        .from('meters')
        .select()
        .eq('owner_id', _userId)
        .eq('is_active', true)
        .order('name');
    return (rows as List).map((e) => Meter.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<Meter> createMeter({
    required String name,
    required String meterNumber,
    String? locationLabel,
  }) async {
    final row = await _client
        .from('meters')
        .insert({
          'owner_id': _userId,
          'name': name.trim(),
          'meter_number': meterNumber.trim(),
          'location_label': locationLabel?.trim(),
        })
        .select()
        .single();
    final meter = Meter.fromJson(Map<String, dynamic>.from(row));
    await _client.from('alert_settings').upsert({
      'meter_id': meter.id,
      'owner_id': _userId,
    });
    return meter;
  }

  @override
  Future<List<MeterReading>> listReadings(String meterId) async {
    final rows = await _client
        .from('readings')
        .select()
        .eq('meter_id', meterId)
        .order('captured_at');
    return (rows as List)
        .map((e) => MeterReading.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> addReading(MeterReading reading) async {
    final payload = reading.toJson()
      ..remove('id')
      ..['created_by'] = _userId
      ..['photo_path'] = null; // le chemin local de l'appareil n'est pas envoyé au cloud
    await _client.from('readings').insert(payload);
  }

  @override
  Future<List<Recharge>> listRecharges(String meterId) async {
    final rows = await _client
        .from('recharges')
        .select()
        .eq('meter_id', meterId)
        .order('recharged_at');
    return (rows as List).map((e) => Recharge.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> addRecharge(Recharge recharge) async {
    final payload = recharge.toJson()
      ..remove('id')
      ..['created_by'] = _userId;
    await _client.from('recharges').insert(payload);
  }

  @override
  Future<AlertSettings> getAlertSettings(String meterId) async {
    final row = await _client
        .from('alert_settings')
        .select()
        .eq('meter_id', meterId)
        .maybeSingle();
    if (row == null) return AlertSettings(meterId: meterId);
    return AlertSettings.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> saveAlertSettings(AlertSettings settings) async {
    final payload = settings.toJson()..['owner_id'] = _userId;
    await _client.from('alert_settings').upsert(payload);
  }
}
