import 'package:intl/intl.dart';

/// Format a date string from API format to a readable format
String formatDate(String dateStr) {
  try {
    final DateTime dateTime = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  } catch (e) {
    return dateStr;
  }
}
