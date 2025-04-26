// modules/history/views/history_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          if (controller.isSelectionMode.value) {
            return AppBar(
              title: Text(
                '${controller.selectedScans.length} Selected',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: controller.cancelSelection,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: controller.deleteSelectedScans,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: controller.shareSelectedScans,
                ),
              ],
            );
          }
          return AppBar(
            title: const Text(
              'Scan History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.select_all, color: Colors.black),
                onPressed: controller.startSelection,
              ),
            ],
          );
        }),
      ),

      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadScans,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search scans...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(
            () =>
                controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: controller.clearSearch,
                    )
                    : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No scan history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your scan history will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
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
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildScansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.filteredScans.length,
      itemBuilder: (context, index) {
        final scan = controller.filteredScans[index];
        return Obx(() {
          final isSelected =
              controller.isSelectionMode.value &&
              controller.selectedScans.contains(scan.id);

          return _buildScanItem(
            scan.id,
            scan.timestamp,
            scan.barcodes.isNotEmpty
                ? scan.barcodes.first.value
                : 'No barcode data',
            scan.barcodes.length > 1
                ? '+ ${scan.barcodes.length - 1} more'
                : '',
            scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown',
            isSelected,
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
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    IconData iconData;
    if (format.contains('QR')) {
      iconData = Icons.qr_code;
    } else if (format.contains('EAN') || format.contains('UPC')) {
      iconData = Icons.shopping_cart;
    } else if (format.contains('CODE_128') || format.contains('CODE_39')) {
      iconData = Icons.inventory;
    } else {
      iconData = Icons.qr_code_scanner;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (controller.isSelectionMode.value)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.red : Colors.grey,
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (additionalInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          additionalInfo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(timestamp),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (!controller.isSelectionMode.value)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
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
          title: const Text('Delete Scan'),
          content: const Text('Are you sure you want to delete this scan?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                controller.deleteScan(id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
