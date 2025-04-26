// modules/scanner/bindings/mobile_scanner_binding.dart
import 'package:get/get.dart';
import '../controllers/mobile_scanner_controller.dart';

class MobileScannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomScannerController>(
      () => CustomScannerController(),
    );
  }
}