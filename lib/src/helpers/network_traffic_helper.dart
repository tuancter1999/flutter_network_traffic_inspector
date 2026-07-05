import 'package:dio/dio.dart';
import 'dart:convert';

abstract class NetworkTrafficHelper {
  // static Map<String, dynamic> headerToMap(Headers headers) {
  //   return headers.map.map(
  //     (k, v) => MapEntry(k, v.length == 1 ? v.first : v),
  //   );
  // }

  static String toPrettyJson(dynamic data) {
    if (data == null) return '{}';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}