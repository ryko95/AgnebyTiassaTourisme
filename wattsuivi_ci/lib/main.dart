import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/watt_suivi_app.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';

  if (AppConfig.cloudEnabled) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
    );
  }

  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // L'application reste utilisable même si les notifications natives
    // ne sont pas encore configurées sur la plateforme de développement.
  }

  runApp(const WattSuiviApp());
}
