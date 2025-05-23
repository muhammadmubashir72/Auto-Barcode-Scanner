import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/utils/scan_utils.dart';
import '../controllers/barcode_home_controller.dart';

class BarcodeHomeView extends GetView<BarcodeHomeController> {
  const BarcodeHomeView({super.key});

  // Parse WiFi QR code to extract SSID, password, and type
  Map<String, String> parseWifiQR(String data) {
    final result = <String, String>{};
    try {
      if (data.startsWith('WIFI:')) {
        data = data.substring(5);
        final ssidMatch = RegExp(r'S:(.*?);').firstMatch(data);
        if (ssidMatch != null && ssidMatch.groupCount >= 1) {
          result['ssid'] = ssidMatch.group(1) ?? '';
        }
        final typeMatch = RegExp(r'T:(.*?);').firstMatch(data);
        if (typeMatch != null && typeMatch.groupCount >= 1) {
          result['type'] = typeMatch.group(1) ?? '';
        }
        final passMatch = RegExp(r'P:(.*?);').firstMatch(data);
        if (passMatch != null && passMatch.groupCount >= 1) {
          result['password'] = passMatch.group(1) ?? '';
        }
      }
    } catch (e) {
      print('Error parsing WiFi QR: $e');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Offline Barcode Scanner',
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
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureCards(),
            const SizedBox(height: 24),
            _buildRecentScansSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToScan,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text('Scan', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildFeatureCard(
              icon: Icons.qr_code_scanner,
              title: 'Barcode Scan',
              description: 'Scan multiple barcodes at once',
              onTap: controller.goToScan,
            ),
            _buildFeatureCard(
              icon: Icons.history,
              title: 'History',
              description: 'View all previous scans',
              onTap: controller.goToHistory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScansSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: controller.goToHistory,
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }
              if (controller.recentScans.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: controller.loadRecentScans,
                color: Colors.red,
                child: ListView.builder(
                  itemCount: controller.recentScans.length,
                  itemBuilder: (context, index) {
                    final scan = controller.recentScans[index];
                    String displayValue = scan.barcodes.isNotEmpty
                        ? scan.barcodes.first.value
                        : 'No barcode data';
                    // Check if it's a WiFi barcode
                    if (scan.barcodes.isNotEmpty &&
                        ScanUtils.getScanType(
                                BarcodeData(value: scan.barcodes.first.value, format: scan.barcodes.first.format)) ==
                            'wifi') {
                      final wifiData = parseWifiQR(scan.barcodes.first.value);
                      if (wifiData.isNotEmpty) {
                        displayValue = wifiData['ssid'] ?? 'Unknown WiFi';
                      }
                    }
                    return _buildScanItem(
                      scan.id,
                      scan.timestamp,
                      displayValue,
                      scan.barcodes.isNotEmpty
                          ? scan.barcodes.first.format
                          : 'Unknown',
                      index + 1, // Serial number
                    );
                  },
                ),
              );
            }),
          ),
        ],
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
          const Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the scan button to get started',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildScanItem(
    String id,
    DateTime timestamp,
    String value,
    String format,
    int serialNumber,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    IconData iconData;
    final scanType = ScanUtils.getScanType(
      BarcodeData(value: value, format: format),
    );
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
      child: InkWell(
        onTap: () => controller.goToScanDetails(id),
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
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

