// app_bindings.dart
import 'package:get/get.dart';
import 'package:scanner_app/data/services/scanner_service.dart';
import 'package:scanner_app/data/services/storage_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Register services
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ScannerService>(ScannerService(), permanent: true);
  }
}
