import 'package:intl/intl.dart';

/// Display timestamps in India Standard Time (Asia/Kolkata).
class IstDateTime {

  static DateTime? parseUtc(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    var raw = iso.trim();
    if (!raw.contains('T')) raw = raw.replaceFirst(' ', 'T');
    if (!raw.endsWith('Z') && !raw.contains('+')) raw = '${raw}Z';
    return DateTime.tryParse(raw);
  }

  /// Example: 16 May 2026, 07:45 PM IST
  static String formatDisplay(String? iso, {String fallback = ''}) {
    final dt = parseUtc(iso);
    if (dt == null) return fallback;
    final local = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(local);
    return '$formatted IST';
  }

  /// Example: 16 May 2026 • 07:45 PM IST
  static String formatBullet(String? iso, {String fallback = ''}) {
    final dt = parseUtc(iso);
    if (dt == null) return fallback;
    final local = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final formatted = DateFormat('dd MMM yyyy • hh:mm a').format(local);
    return '$formatted IST';
  }

  static String formatFromDateTime(DateTime? dt) {
    if (dt == null) return '';
    return formatDisplay(dt.toUtc().toIso8601String());
  }
}
