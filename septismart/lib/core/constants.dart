class AppConstants {
  // Change this to your Spring Boot base URL
  // e.g. http://10.0.2.2:8080 for Android emulator, or your LAN IP for device
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Example endpoint that returns: [{"month":"January","filledPercentage":98.2}, ...]
  static const String monthlyReportPath = '/api/reports';
}
