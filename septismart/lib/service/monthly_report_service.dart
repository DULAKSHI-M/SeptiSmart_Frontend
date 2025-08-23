import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/monthly_report.dart';

class MonthlyReportService {
  final http.Client _client;
  MonthlyReportService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<MonthlyReport>> fetchMonthlyReports() async {
    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.monthlyReportPath}');
    final resp = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (resp.statusCode != 200) {
      throw Exception('Failed to load monthly reports: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body);
    if (body is List) {
      return body.map((e) => MonthlyReport.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Unexpected response shape: ${resp.body}');
    }
  }
}
