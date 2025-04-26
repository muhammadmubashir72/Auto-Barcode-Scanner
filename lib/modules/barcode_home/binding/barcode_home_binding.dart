// modules/barcode_home/bindings/barcode_home_binding.dart
import 'package:get/get.dart';
import '../controllers/barcode_home_controller.dart';

class BarcodeHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarcodeHomeController>(
      () => BarcodeHomeController(),
    );
  }
}