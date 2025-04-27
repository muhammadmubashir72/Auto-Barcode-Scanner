// modules/barcode_home/controllers/barcode_home_controller.dart
import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';

class BarcodeHomeController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();

  final recentScans = <ScanResult>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentScans();
  }

  Future<void> loadRecentScans() async {
    isLoading.value = true;
    try {
      final allScans = await storageService.getAllScans();
      recentScans.value = allScans.take(5).toList();
      print('Loaded ${recentScans.length} recent scans');
    } catch (e) {
      print('Error loading recent scans: $e');
      Get.snackbar('Error', 'Failed to load recent scans');
    } finally {
      isLoading.value = false;
    }
  }

  void goToScan() {
    Get.toNamed('/scanner');
  }

  void goToHistory() {
    Get.toNamed('/history');
  }

  void goToScanDetails(String id) {
    Get.toNamed('/scan_details', arguments: id);
  }
}
