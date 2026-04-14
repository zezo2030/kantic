import 'package:intl/intl.dart';

/// Formats a slot string `HH:mm-HH:mm` for display using a 12-hour clock.
/// Canonical values sent to the API stay in 24-hour form; this is UI-only.
String formatEventTimeSlotRange12h(String slot, String localeName) {
  final idx = slot.indexOf('-');
  if (idx <= 0 || idx >= slot.length - 1) return slot;
  final startS = slot.substring(0, idx).trim();
  final endS = slot.substring(idx + 1).trim();
  final sp = startS.split(':');
  final ep = endS.split(':');
  if (sp.length < 2 || ep.length < 2) return slot;
  final sh = int.tryParse(sp[0]);
  final sm = int.tryParse(sp[1]);
  final eh = int.tryParse(ep[0]);
  final em = int.tryParse(ep[1]);
  if (sh == null || sm == null || eh == null || em == null) return slot;

  final base = DateTime(2000, 1, 1);
  final start = DateTime(base.year, base.month, base.day, sh, sm);
  var end = DateTime(base.year, base.month, base.day, eh, em);
  if (!end.isAfter(start)) {
    end = end.add(const Duration(days: 1));
  }

  final fmt = DateFormat.jm(localeName);
  return '${fmt.format(start)} – ${fmt.format(end)}';
}
