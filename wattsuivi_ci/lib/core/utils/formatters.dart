import 'package:intl/intl.dart';

final _xof = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

String formatXof(num value) => _xof.format(value);
String formatDate(DateTime value) => _date.format(value.toLocal());
String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());
