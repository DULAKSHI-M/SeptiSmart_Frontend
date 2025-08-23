class MonthlyReport {
  final String month;
  final double filledPercentage;

  MonthlyReport({
    required this.month,
    required this.filledPercentage,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month: (json['month'] ?? '').toString(),
      filledPercentage: (json['filledPercentage'] is int)
          ? (json['filledPercentage'] as int).toDouble()
          : (json['filledPercentage'] as num).toDouble(),
    );
  }
}
