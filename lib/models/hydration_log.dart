import 'dart:convert';

class HydrationLog {
  final DateTime timestamp;
  final int milliliters;

  HydrationLog({required this.timestamp, required this.milliliters});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'milliliters': milliliters,
      };

  factory HydrationLog.fromJson(Map<String, dynamic> json) => HydrationLog(
        timestamp: DateTime.parse(json['timestamp'] as String),
        milliliters: json['milliliters'] as int,
      );

  static String encodeList(List<HydrationLog> logs) =>
      jsonEncode(logs.map((e) => e.toJson()).toList());

  static List<HydrationLog> decodeList(String raw) {
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => HydrationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
