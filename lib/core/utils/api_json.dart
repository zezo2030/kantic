/// Helpers for parsing NestJS-style API payloads (`data` wrapper optional).
Map<String, dynamic> unwrapData(dynamic json) {
  if (json is Map<String, dynamic>) {
    final inner = json['data'];
    if (inner is Map<String, dynamic>) return inner;
    return json;
  }
  if (json is Map) return Map<String, dynamic>.from(json);
  return {};
}

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<Map<String, dynamic>> asJsonList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => asJsonMap(e)).toList();
}

double? toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
