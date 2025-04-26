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

// import 'package:get/get.dart';
// import 'package:scanner_app/data/services/scanner_service.dart';
// import 'package:scanner_app/data/services/storage_service.dart';
// import 'package:scanner_app/modules/barcode_home/controllers/barcode_home_controller.dart';

// class AppBindings extends Bindings {
//   @override
//   Future<void> dependencies() async {
//     // Initialize and register services
//     final storageService = StorageService();
//     await storageService.init();
//     Get.put(storageService, permanent: true);
//     Get.put(ScannerService(), permanent: true);
    
//     // Register controllers
//     Get.lazyPut<BarcodeHomeController>(() => BarcodeHomeController(), fenix: true);
//   }
// }