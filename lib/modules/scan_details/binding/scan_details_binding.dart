// modules/scan_details/bindings/scan_details_binding.dart
import 'package:get/get.dart';
import '../controllers/scan_details_controller.dart';

class ScanDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanDetailsController>(
      () => ScanDetailsController(),
    );
  }
}