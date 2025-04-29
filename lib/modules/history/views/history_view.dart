import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/utils/scan_utils.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => controller.isSelectionMode.value
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  tooltip: 'Cancel Selection',
                  onPressed: controller.cancelSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.black),
                  tooltip: 'Select Scans',
                  onPressed: controller.startSelection,
                )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadScans,
                color: Colors.red,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  }
                  if (controller.scans.isEmpty) {
                    return _buildEmptyState();
                  }
                  if (controller.filteredScans.isEmpty) {
                    return _buildNoResultsState();
                  }
                  return _buildScansList();
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        return controller.isSelectionMode.value
            ? BottomAppBar(
                color: Colors.white,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: controller.isProcessing.value
                      ? const Center(child: CircularProgressIndicator(color: Colors.red))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${controller.selectedScans.length} selected',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_box, color: Colors.black),
                                  tooltip: 'Select All Scans',
                                  onPressed: controller.filteredScans.isNotEmpty
                                      ? controller.selectAll
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.black),
                                  tooltip: 'Share Selected Scans',
                                  onPressed: controller.selectedScans.isNotEmpty
                                      ? controller.shareSelectedScans
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Selected Scans',
                                  onPressed: controller.selectedScans.isNotEmpty
                                      ? controller.deleteSelectedScans
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear_all, color: Colors.red),
                                  tooltip: 'Clear All History',
                                  onPressed: controller.scans.isNotEmpty
                                      ? controller.clearHistory
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              )
            : const SizedBox.shrink();
      }),
    );
  }

  Widget _buildFilterChips() {
    final filterTypes = [
      {'type': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'type': 'wifi', 'label': 'WiFi', 'icon': Icons.wifi},
      {'type': 'url', 'label': 'Website', 'icon': Icons.link},
      {'type': 'phone', 'label': 'Phone', 'icon': Icons.phone},
      {'type': 'vcard', 'label': 'Contact', 'icon': Icons.contact_page},
      {'type': 'qr', 'label': 'QR Code', 'icon': Icons.qr_code},
      {'type': 'barcode', 'label': 'Barcode', 'icon': Icons.qr_code_scanner},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filterTypes.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() {
              final isSelected = controller.filterType.value == filter['type'];
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: Colors.red,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (selected) {
                  controller.setFilterType(filter['type'] as String);
                },
              );
            }),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: controller.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search scans...',
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        suffixIcon: Obx(
          () => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink(),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No scan history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your scan history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term or filter',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildScansList() {
    return ListView.builder(
      itemCount: controller.filteredScans.length,
      itemBuilder: (context, index) {
        final scan = controller.filteredScans[index];
        return Obx(() {
          final isSelected = controller.isSelectionMode.value && controller.selectedScans.contains(scan.id);
          return _buildScanItem(
            scan.id,
            scan.timestamp,
            scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No barcode data',
            scan.barcodes.length > 1 ? '+ ${scan.barcodes.length - 1} more' : '',
            scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown',
            isSelected,
            index + 1,
          );
        });
      },
    );
  }

  Widget _buildScanItem(
    String id,
    DateTime timestamp,
    String value,
    String additionalInfo,
    String format,
    bool isSelected,
    int serialNumber,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    IconData iconData;
    final scanType = ScanUtils.getScanType(BarcodeData(value: value, format: format));
    switch (scanType) {
      case 'wifi':
        iconData = Icons.wifi;
        break;
      case 'url':
        iconData = Icons.link;
        break;
      case 'phone':
        iconData = Icons.phone;
        break;
      case 'vcard':
        iconData = Icons.contact_page;
        break;
      case 'qr':
        iconData = Icons.qr_code;
        break;
      case 'barcode':
        iconData = Icons.qr_code_scanner;
        break;
      default:
        iconData = Icons.qr_code_scanner;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black),
      ),
      color: isSelected ? Colors.red.withOpacity(0.1) : Colors.white,
      child: InkWell(
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleSelection(id);
          } else {
            controller.goToScanDetails(id);
          }
        },
        onLongPress: () {
          if (!controller.isSelectionMode.value) {
            controller.startSelection();
            controller.toggleSelection(id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$serialNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (controller.isSelectionMode.value)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.red : Colors.black,
                    size: 24,
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (additionalInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          additionalInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              if (!controller.isSelectionMode.value)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  tooltip: 'Delete Scan',
                  onPressed: () => _showDeleteConfirmation(id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Scan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this scan?',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                controller.deleteScan(id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
