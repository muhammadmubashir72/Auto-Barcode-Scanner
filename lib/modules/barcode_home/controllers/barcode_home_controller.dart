import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:scanner_app/utils/scan_utils.dart';

class BarcodeHomeController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();

  final recentScans = <ScanResult>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentScans();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh scans when the view is fully loaded or revisited
    loadRecentScans();
  }
Future<void> saveScanAndUpdate(ScanResult newScan) async {
  try {
    await storageService.saveScanResult(newScan);
    print('Scan saved with ID: ${newScan.id}');
    await loadRecentScans();
    recentScans.refresh(); // Ensure UI updates
  } catch (e) {
    print('Error saving scan: $e');
    ScanUtils.showErrorSnackbar('Error', 'Failed to save the scan');
  }
}
Future<void> loadRecentScans() async {
  isLoading.value = true;
  try {
    final allScans = await storageService.getAllScans();
    recentScans.value = allScans
        .where((scan) => scan != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    recentScans.refresh(); // Force UI update
    print('Loaded ${recentScans.length} recent scans: ${recentScans.map((s) => s.id).toList()}');
  } catch (e) {
    print('Error loading recent scans: $e');
    ScanUtils.showErrorSnackbar('Error', 'Failed to load recent scans');
  } finally {
    isLoading.value = false;
  }
}

Future<void> _navigateAndRefresh(String routeName, {dynamic arguments}) async {
  final result = await Get.toNamed(routeName, arguments: arguments);
  print('$routeName returned result: $result');

  // Always refresh the scans list
  await loadRecentScans();

  // If the result is a scan ID (String), navigate to scan details
  if (result is String) {
    await Get.toNamed('/scan_details', arguments: result);
  }
}
  // Future<void> _navigateAndRefresh(
  //   String routeName, {
  //   dynamic arguments,
  // }) async {
  //   final result = await Get.toNamed(routeName, arguments: arguments);
  //   // Always refresh scans after any scan attempt or navigation
  //   print('$routeName returned result: $result');
  //   if (result == true) {
  //     loadRecentScans();
  //   }
  // }

  void goToScan() async {
    await _navigateAndRefresh('/scanner');
  }

  void goToHistory() {
    Get.toNamed('/history');
  }

  void goToScanDetails(String id) async {
    await _navigateAndRefresh('/scan_details', arguments: id);
  }
}
