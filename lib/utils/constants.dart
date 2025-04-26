class AppConstants {
  // App info
  static const String appName = 'Barcode Scanner';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String homeRoute = '/barcode_home';
  static const String scannerRoute = '/scanner';
  static const String historyRoute = '/history';
  static const String scanDetailsRoute = '/scan_details';
  
  // Database
  static const String dbName = 'barcode_scanner.db';
  static const String scansTable = 'scans';
  
  // Directories
  static const String imagesDir = 'scan_images';
  
  // Timeouts
  static const int scanCooldownMs = 1000; // 1 second cooldown between scans
}