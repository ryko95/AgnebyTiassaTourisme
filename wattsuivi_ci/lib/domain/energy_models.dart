import 'dart:math' as math;

class Meter {
  const Meter({
    required this.id,
    required this.name,
    required this.meterNumber,
    required this.createdAt,
    this.locationLabel,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String meterNumber;
  final String? locationLabel;
  final DateTime createdAt;
  final bool isActive;

  factory Meter.fromJson(Map<String, dynamic> json) => Meter(
        id: json['id'] as String,
        name: json['name'] as String,
        meterNumber: json['meter_number'] as String,
        locationLabel: json['location_label'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'meter_number': meterNumber,
        'location_label': locationLabel,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive,
      };
}

enum ReadingSource { manual, scan }

class MeterReading {
  const MeterReading({
    required this.id,
    required this.meterId,
    required this.capturedAt,
    required this.balanceKwh,
    required this.source,
    this.photoPath,
    this.rawOcrText,
  });

  final String id;
  final String meterId;
  final DateTime capturedAt;
  final double balanceKwh;
  final ReadingSource source;
  final String? photoPath;
  final String? rawOcrText;

  factory MeterReading.fromJson(Map<String, dynamic> json) => MeterReading(
        id: json['id'] as String,
        meterId: json['meter_id'] as String,
        capturedAt: DateTime.parse(json['captured_at'] as String),
        balanceKwh: (json['balance_kwh'] as num).toDouble(),
        source: (json['source'] as String? ?? 'manual') == 'scan'
            ? ReadingSource.scan
            : ReadingSource.manual,
        photoPath: json['photo_path'] as String?,
        rawOcrText: json['raw_ocr_text'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meter_id': meterId,
        'captured_at': capturedAt.toIso8601String(),
        'balance_kwh': balanceKwh,
        'source': source.name,
        'photo_path': photoPath,
        'raw_ocr_text': rawOcrText,
      };
}

enum RechargeChannel { orangeMoney, mtnMomo, moovMoney, wave, cash, other }

extension RechargeChannelLabel on RechargeChannel {
  String get label => switch (this) {
        RechargeChannel.orangeMoney => 'Orange Money',
        RechargeChannel.mtnMomo => 'MTN MoMo',
        RechargeChannel.moovMoney => 'Moov Money',
        RechargeChannel.wave => 'Wave',
        RechargeChannel.cash => 'Espèces / agence',
        RechargeChannel.other => 'Autre',
      };
}

class Recharge {
  const Recharge({
    required this.id,
    required this.meterId,
    required this.rechargedAt,
    required this.amountXof,
    required this.channel,
    this.energyKwh,
    this.reference,
    this.tokenLast4,
  });

  final String id;
  final String meterId;
  final DateTime rechargedAt;
  final int amountXof;
  final double? energyKwh;
  final RechargeChannel channel;
  final String? reference;
  final String? tokenLast4;

  factory Recharge.fromJson(Map<String, dynamic> json) => Recharge(
        id: json['id'] as String,
        meterId: json['meter_id'] as String,
        rechargedAt: DateTime.parse(json['recharged_at'] as String),
        amountXof: (json['amount_xof'] as num).toInt(),
        energyKwh: (json['energy_kwh'] as num?)?.toDouble(),
        channel: RechargeChannel.values.firstWhere(
          (value) => value.name == (json['channel'] as String? ?? 'other'),
          orElse: () => RechargeChannel.other,
        ),
        reference: json['reference'] as String?,
        tokenLast4: json['token_last4'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meter_id': meterId,
        'recharged_at': rechargedAt.toIso8601String(),
        'amount_xof': amountXof,
        'energy_kwh': energyKwh,
        'channel': channel.name,
        'reference': reference,
        'token_last4': tokenLast4,
      };
}

class AlertSettings {
  const AlertSettings({
    required this.meterId,
    this.lowBalanceKwh = 10,
    this.lowAutonomyDays = 3,
    this.highConsumptionRatio = 1.35,
    this.notificationsEnabled = true,
  });

  final String meterId;
  final double lowBalanceKwh;
  final double lowAutonomyDays;
  final double highConsumptionRatio;
  final bool notificationsEnabled;

  AlertSettings copyWith({
    double? lowBalanceKwh,
    double? lowAutonomyDays,
    double? highConsumptionRatio,
    bool? notificationsEnabled,
  }) =>
      AlertSettings(
        meterId: meterId,
        lowBalanceKwh: lowBalanceKwh ?? this.lowBalanceKwh,
        lowAutonomyDays: lowAutonomyDays ?? this.lowAutonomyDays,
        highConsumptionRatio: highConsumptionRatio ?? this.highConsumptionRatio,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  factory AlertSettings.fromJson(Map<String, dynamic> json) => AlertSettings(
        meterId: json['meter_id'] as String,
        lowBalanceKwh: (json['low_balance_kwh'] as num? ?? 10).toDouble(),
        lowAutonomyDays: (json['low_autonomy_days'] as num? ?? 3).toDouble(),
        highConsumptionRatio:
            (json['high_consumption_ratio'] as num? ?? 1.35).toDouble(),
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'meter_id': meterId,
        'low_balance_kwh': lowBalanceKwh,
        'low_autonomy_days': lowAutonomyDays,
        'high_consumption_ratio': highConsumptionRatio,
        'notifications_enabled': notificationsEnabled,
      };
}

class ConsumptionSegment {
  const ConsumptionSegment({
    required this.start,
    required this.end,
    required this.days,
    required this.rechargedKwh,
    required this.consumedKwh,
  });

  final MeterReading start;
  final MeterReading end;
  final double days;
  final double rechargedKwh;
  final double consumedKwh;

  double get averageKwhPerDay => days <= 0 ? 0 : consumedKwh / days;
}

class EnergySummary {
  const EnergySummary({
    required this.segments,
    required this.currentBalanceEstimateKwh,
    required this.averageKwhPerDay,
    required this.totalConsumedKwh,
    required this.dataWarnings,
    this.autonomyDays,
    this.estimatedDepletionAt,
  });

  final List<ConsumptionSegment> segments;
  final double currentBalanceEstimateKwh;
  final double averageKwhPerDay;
  final double totalConsumedKwh;
  final double? autonomyDays;
  final DateTime? estimatedDepletionAt;
  final List<String> dataWarnings;

  double get latestDailyAverage =>
      segments.isEmpty ? 0 : segments.last.averageKwhPerDay;

  bool isHighConsumption(double ratio) {
    if (segments.length < 2 || averageKwhPerDay <= 0) return false;
    final baselineSegments = segments.take(segments.length - 1).toList();
    final baselineDays = baselineSegments.fold<double>(0, (sum, s) => sum + s.days);
    if (baselineDays <= 0) return false;
    final baselineKwh =
        baselineSegments.fold<double>(0, (sum, s) => sum + s.consumedKwh);
    final baseline = baselineKwh / baselineDays;
    return baseline > 0 && latestDailyAverage > baseline * ratio;
  }
}

class EnergyAnalytics {
  const EnergyAnalytics._();

  static EnergySummary build({
    required List<MeterReading> readings,
    required List<Recharge> recharges,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final orderedReadings = [...readings]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final orderedRecharges = [...recharges]
      ..sort((a, b) => a.rechargedAt.compareTo(b.rechargedAt));

    if (orderedReadings.isEmpty) {
      return const EnergySummary(
        segments: [],
        currentBalanceEstimateKwh: 0,
        averageKwhPerDay: 0,
        totalConsumedKwh: 0,
        dataWarnings: ['Ajoutez au moins un relevé pour commencer le suivi.'],
      );
    }

    final warnings = <String>[];
    final segments = <ConsumptionSegment>[];

    for (var i = 0; i < orderedReadings.length - 1; i++) {
      final start = orderedReadings[i];
      final end = orderedReadings[i + 1];
      final minutes = end.capturedAt.difference(start.capturedAt).inMinutes;
      if (minutes <= 0) continue;
      final days = minutes / 1440.0;

      final inPeriod = orderedRecharges.where((recharge) {
        return recharge.rechargedAt.isAfter(start.capturedAt) &&
            !recharge.rechargedAt.isAfter(end.capturedAt);
      }).toList();

      final unknownRechargeCount = inPeriod.where((r) => r.energyKwh == null).length;
      if (unknownRechargeCount > 0) {
        warnings.add(
          '$unknownRechargeCount recharge(s) sans kWh entre deux relevés : la consommation de cette période peut être sous-estimée.',
        );
      }

      final rechargeKwh = inPeriod.fold<double>(
        0,
        (sum, recharge) => sum + (recharge.energyKwh ?? 0),
      );
      final rawConsumed = start.balanceKwh + rechargeKwh - end.balanceKwh;

      if (rawConsumed < -0.01) {
        warnings.add(
          'Incohérence détectée entre les relevés du ${start.capturedAt.day}/${start.capturedAt.month} et du ${end.capturedAt.day}/${end.capturedAt.month}. Une recharge en kWh est peut-être manquante.',
        );
        continue;
      }

      segments.add(
        ConsumptionSegment(
          start: start,
          end: end,
          days: days,
          rechargedKwh: rechargeKwh,
          consumedKwh: math.max(0.0, rawConsumed).toDouble(),
        ),
      );
    }

    final totalDays = segments.fold<double>(0, (sum, segment) => sum + segment.days);
    final totalConsumed =
        segments.fold<double>(0, (sum, segment) => sum + segment.consumedKwh);
    final average = totalDays > 0 ? totalConsumed / totalDays : 0.0;

    final lastReading = orderedReadings.last;
    final rechargeAfterLast = orderedRecharges.where(
      (recharge) => recharge.rechargedAt.isAfter(lastReading.capturedAt),
    );
    final addedSinceLast = rechargeAfterLast.fold<double>(
      0,
      (sum, recharge) => sum + (recharge.energyKwh ?? 0),
    );
    final minutesSinceLast = math.max(0, clock.difference(lastReading.capturedAt).inMinutes).toInt();
    final elapsedDays = minutesSinceLast / 1440.0;
    final estimatedUsedSinceLast = average * elapsedDays;
    final currentEstimate = math.max(
      0.0,
      lastReading.balanceKwh + addedSinceLast - estimatedUsedSinceLast,
    ).toDouble();

    double? autonomy;
    DateTime? depletion;
    if (average > 0) {
      autonomy = currentEstimate / average;
      depletion = clock.add(Duration(minutes: (autonomy * 1440).round()));
    }

    return EnergySummary(
      segments: segments,
      currentBalanceEstimateKwh: currentEstimate,
      averageKwhPerDay: average,
      totalConsumedKwh: totalConsumed,
      autonomyDays: autonomy,
      estimatedDepletionAt: depletion,
      dataWarnings: warnings.toSet().toList(),
    );
  }
}
