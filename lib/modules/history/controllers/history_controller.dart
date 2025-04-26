// modules/history/controllers/history_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:share_plus/share_plus.dart';

class HistoryController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  
  final scans = <ScanResult>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final filteredScans = <ScanResult>[].obs;
  
  // Selection mode
  final isSelectionMode = false.obs;
  final selectedScans = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadScans();
    
    // Set up reaction for search
    ever(searchQuery, (_) {
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
    if (searchQuery.value.isEmpty) {
      filteredScans.value = scans;
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredScans.value = scans.where((scan) {
        // Search in barcode values
        final barcodeMatch = scan.barcodes.any((barcode) => 
          barcode.value.toLowerCase().contains(query));
        
        // Search in extracted text if available
        final textMatch = scan.extractedText != null && 
          scan.extractedText!.toLowerCase().contains(query);
        
        return barcodeMatch || textMatch;
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
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
    
    // If no items are selected, exit selection mode
    if (selectedScans.isEmpty) {
      isSelectionMode.value = false;
    }
  }
  
  Future<void> deleteSelectedScans() async {
    if (selectedScans.isEmpty) return;
    
    try {
      // Show confirmation dialog
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
      
      // Delete all selected scans
      for (final id in selectedScans) {
        await storageService.deleteScan(id);
      }
      
      // Reload scans and exit selection mode
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
      // Get all selected scan results
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
      
      // Prepare text to share
      String shareText = 'Barcode Scans:\n\n';
      
      // Prepare images to share
      final images = <XFile>[];
      
      for (int i = 0; i < selectedResults.length; i++) {
        final scan = selectedResults[i];
        
        shareText += '--- Scan ${i + 1} (${scan.timestamp}) ---\n';
        for (int j = 0; j < scan.barcodes.length; j++) {
          final barcode = scan.barcodes[j];
          shareText += '${j + 1}. ${barcode.value} (${barcode.format})\n';
        }
        shareText += '\n';
        
        // Add image if available
        if (scan.imagePath != null) {
          images.add(XFile(scan.imagePath!));
        }
      }
      
      // Share
      if (images.isNotEmpty) {
        await Share.shareXFiles(
          images,
          text: shareText,
        );
      } else {
        await Share.share(shareText);
      }
      
      // Exit selection mode after sharing
      cancelSelection();
    } catch (e) {
      print('Error sharing selected scans: $e');
      Get.snackbar('Error', 'Failed to share selected scans');
    }
  }
}
