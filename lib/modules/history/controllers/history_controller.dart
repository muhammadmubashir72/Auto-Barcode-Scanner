// modules/history/controllers/history_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:scanner_app/utils/scan_utils.dart';
import 'package:share_plus/share_plus.dart';

class HistoryController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  
  final scans = <ScanResult>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final filteredScans = <ScanResult>[].obs;
  final filterType = 'all'.obs; // New: Tracks current filter type
  
  // Selection mode
  final isSelectionMode = false.obs;
  final selectedScans = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScans();
    
    // Set up reactions for search and filter
    everAll([searchQuery, filterType], (_) {
      _filterScans();
    });
  }

  Future<void> loadScans() async {
    isLoading.value = true;
    try {
      final allScans = await storageService.getAllScans();
      scans.value = allScans;
      _filterScans();
    } catch (e) {
      print('Error loading scans: $e');
      Get.snackbar('Error', 'Failed to load scan history');
    } finally {
      isLoading.value = false;
    }
  }

  void _filterScans() {
    var result = scans.toList();

    // Apply search query filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((scan) {
        final barcodeMatch = scan.barcodes.any((barcode) => 
          barcode.value.toLowerCase().contains(query));
        final textMatch = scan.extractedText != null && 
          scan.extractedText!.toLowerCase().contains(query);
        return barcodeMatch || textMatch;
      }).toList();
    }

    // Apply type filter
    if (filterType.value != 'all') {
      result = result.where((scan) {
        return scan.barcodes.any((barcode) {
          final scanType = ScanUtils.getScanType(barcode);
          return scanType == filterType.value;
        });
      }).toList();
    }

    filteredScans.value = result;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  void setFilterType(String type) {
    filterType.value = type;
  }

  void goToScanDetails(String id) {
    Get.toNamed('/scan_details', arguments: id);
  }

  Future<void> deleteScan(String id) async {
    try {
      await storageService.deleteScan(id);
      await loadScans();
      Get.snackbar('Success', 'Scan deleted successfully');
    } catch (e) {
      print('Error deleting scan: $e');
      Get.snackbar('Error', 'Failed to delete scan');
    }
  }
  
  // Selection mode methods
  void startSelection() {
    isSelectionMode.value = true;
    selectedScans.clear();
  }
  
  void cancelSelection() {
    isSelectionMode.value = false;
    selectedScans.clear();
  }
  
  void toggleSelection(String id) {
    if (selectedScans.contains(id)) {
      selectedScans.remove(id);
    } else {
      selectedScans.add(id);
    }
    
    if (selectedScans.isEmpty) {
      isSelectionMode.value = false;
    }
  }
  
  Future<void> deleteSelectedScans() async {
    if (selectedScans.isEmpty) return;
    
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Selected Scans'),
          content: Text('Are you sure you want to delete ${selectedScans.length} selected scans?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      for (final id in selectedScans) {
        await storageService.deleteScan(id);
      }
      
      await loadScans();
      cancelSelection();
      
      Get.snackbar('Success', 'Selected scans deleted successfully');
    } catch (e) {
      print('Error deleting selected scans: $e');
      Get.snackbar('Error', 'Failed to delete selected scans');
    }
  }
  
  Future<void> shareSelectedScans() async {
    if (selectedScans.isEmpty) return;
    
    try {
      final selectedResults = <ScanResult>[];
      for (final id in selectedScans) {
        final scan = await storageService.getScanById(id);
        if (scan != null) {
          selectedResults.add(scan);
        }
      }
      
      if (selectedResults.isEmpty) {
        Get.snackbar('Error', 'No valid scans to share');
        return;
      }
      
      String shareText = 'Barcode Scans:\n\n';
      final images = <XFile>[];
      
      for (int i = 0; i < selectedResults.length; i++) {
        final scan = selectedResults[i];
        
        shareText += '--- Scan ${i + 1} (${scan.timestamp}) ---\n';
        for (int j = 0; j < scan.barcodes.length; j++) {
          final barcode = scan.barcodes[j];
          shareText += '${j + 1}. ${barcode.value} (${barcode.format})\n';
        }
        shareText += '\n';
        
        if (scan.imagePath != null) {
          images.add(XFile(scan.imagePath!));
        }
      }
      
      if (images.isNotEmpty) {
        await Share.shareXFiles(
          images,
          text: shareText,
        );
      } else {
        await Share.share(shareText);
      }
      
      cancelSelection();
    } catch (e) {
      print('Error sharing selected scans: $e');
      Get.snackbar('Error', 'Failed to share selected scans');
    }
  }
}
