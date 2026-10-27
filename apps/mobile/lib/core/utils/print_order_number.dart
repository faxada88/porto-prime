/// Human-readable four-digit daily order number shown to people.
 /// Never substitute it for the internal ID used by API calls,
 /// or for the separate delivery confirmation PIN.
String printOrderNumber(dynamic order) {
  if (order is! Map) return '—';
  final number = int.tryParse((order['displayNumber'] ?? '').toString());
  if (number == null || number < 1 || number > 9999) return '—';
  return number.toString().padLeft(4, '0');
}
