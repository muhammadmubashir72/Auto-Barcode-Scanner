// modules/barcode_home/views/barcode_home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import '../controllers/barcode_home_controller.dart';

class BarcodeHomeView extends GetView<BarcodeHomeController> {
  const BarcodeHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadRecentScans,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildButtonSection(), // Updated to include both buttons
                const SizedBox(height: 32),
                _buildRecentScansSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New widget to hold both buttons side by side
  Widget _buildButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildScanButton()),
        const SizedBox(width: 16),
        Expanded(child: _buildHistoryButton()),
      ],
    );
  }

  // Scan Barcode Button
  Widget _buildScanButton() {
    return GestureDetector(
      onTap: controller.goToScan,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan Barcode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // History Button
  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: controller.goToHistory,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansSection() {
    return Column(
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.recentScans.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentScans.length > 3 ? 3 : controller.recentScans.length,
            itemBuilder: (context, index) {
              final scan = controller.recentScans[index];
              return _buildScanItem(
                scan.id,
                scan.timestamp,
                scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No barcode data',
                scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown',
              );
            },
          );
        }),
      ],
    );
  }


  // Widget _buildHistoryItem(ScanResult scan) {
  //   final dateFormat = DateFormat('MMM d');
  //   final timeFormat = DateFormat('h:mm a');

  //   IconData iconData;
  //   String value = scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No data';
  //   String format = scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown';

  //   if (format.contains('QR')) {
  //     iconData = Icons.qr_code;
  //   } else if (format.contains('EAN') || format.contains('UPC')) {
  //     iconData = Icons.shopping_cart;
  //   } else if (format.contains('CODE_128') || format.contains('CODE_39')) {
  //     iconData = Icons.inventory;
  //   } else {
  //     iconData = Icons.qr_code_scanner;
  //   }

  //   return GestureDetector(
  //     onTap: () => controller.goToScanDetails(scan.id),
  //     child: Container(
  //       width: 120,
  //       margin: const EdgeInsets.only(right: 12),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withOpacity(0.2),
  //             blurRadius: 5,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: Colors.red.withOpacity(0.1),
  //               shape: BoxShape.circle,
  //             ),
  //             child: Icon(
  //               iconData,
  //               color: Colors.red,
  //               size: 28,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             dateFormat.format(scan.timestamp),
  //             style: const TextStyle(
  //               fontSize: 12,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           Text(
  //             timeFormat.format(scan.timestamp),
  //             style: TextStyle(
  //               fontSize: 10,
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             value.length > 10 ? '${value.substring(0, 10)}...' : value,
  //             style: const TextStyle(
  //               fontSize: 10,
  //               color: Colors.black87,
  //             ),
  //             maxLines: 1,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recent scans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the scan button to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanItem(String id, DateTime timestamp, String value, String format) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.goToScanDetails(id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: Colors.red,
                  size: 28,
                ),
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
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // modules/barcode_home/views/barcode_home_view.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import '../controllers/barcode_home_controller.dart';

// class BarcodeHomeView extends GetView<BarcodeHomeController> {
//   const BarcodeHomeView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Barcode Scanner',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: RefreshIndicator(
//         onRefresh: controller.loadRecentScans,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildScanButton(),
//                 const SizedBox(height: 32),
//                 _buildRecentScansSection(),
//                 const SizedBox(height: 32),
//                 _buildHistorySection(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildScanButton() {
//     return GestureDetector(
//       onTap: controller.goToScan,
//       child: Container(
//         width: double.infinity,
//         height: 180,
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.qr_code_scanner,
//                 size: 48,
//                 color: Colors.red,
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Scan Barcode',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentScansSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Recent Scans',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             TextButton(
//               onPressed: controller.goToHistory,
//               child: const Text(
//                 'View All',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Obx(() {
//           if (controller.isLoading.value) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }

//           if (controller.recentScans.isEmpty) {
//             return _buildEmptyState();
//           }

//           return ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: controller.recentScans.length > 3 ? 3 : controller.recentScans.length,
//             itemBuilder: (context, index) {
//               final scan = controller.recentScans[index];
//               return _buildScanItem(scan.id, scan.timestamp, 
//                 scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No barcode data',
//                 scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown');
//             },
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildHistorySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'History',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             TextButton(
//               onPressed: controller.goToHistory,
//               child: const Text(
//                 'View All',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Obx(() {
//           if (controller.isLoading.value) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }

//           if (controller.recentScans.isEmpty) {
//             return _buildEmptyState();
//           }

//           return Container(
//             height: 120,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: controller.recentScans.length,
//               itemBuilder: (context, index) {
//                 final scan = controller.recentScans[index];
//                 return _buildHistoryItem(scan);
//               },
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildHistoryItem(ScanResult scan) {
//     final dateFormat = DateFormat('MMM d');
//     final timeFormat = DateFormat('h:mm a');
    
//     IconData iconData;
//     String value = scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No data';
//     String format = scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown';
    
//     if (format.contains('QR')) {
//       iconData = Icons.qr_code;
//     } else if (format.contains('EAN') || format.contains('UPC')) {
//       iconData = Icons.shopping_cart;
//     } else if (format.contains('CODE_128') || format.contains('CODE_39')) {
//       iconData = Icons.inventory;
//     } else {
//       iconData = Icons.qr_code_scanner;
//     }

//     return GestureDetector(
//       onTap: () => controller.goToScanDetails(scan.id),
//       child: Container(
//         width: 120,
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 iconData,
//                 color: Colors.red,
//                 size: 28,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               dateFormat.format(scan.timestamp),
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               timeFormat.format(scan.timestamp),
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value.length > 10 ? '${value.substring(0, 10)}...' : value,
//               style: const TextStyle(
//                 fontSize: 10,
//                 color: Colors.black87,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 32),
//       width: double.infinity,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.qr_code_scanner,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No recent scans',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the scan button to get started',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildScanItem(String id, DateTime timestamp, String value, String format) {
//     final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
//     IconData iconData;
//     if (format.contains('QR')) {
//       iconData = Icons.qr_code;
//     } else if (format.contains('EAN') || format.contains('UPC')) {
//       iconData = Icons.shopping_cart;
//     } else if (format.contains('CODE_128') || format.contains('CODE_39')) {
//       iconData = Icons.inventory;
//     } else {
//       iconData = Icons.qr_code_scanner;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: () => controller.goToScanDetails(id),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   iconData,
//                   color: Colors.red,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       value,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       dateFormat.format(timestamp),
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.arrow_forward_ios,
//                 size: 16,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../controllers/barcode_home_controller.dart';

// class BarcodeHomeView extends GetView<BarcodeHomeController> {
//   const BarcodeHomeView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Barcode Scanner',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: RefreshIndicator(
//         onRefresh: controller.loadRecentScans,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildScanButton(),
//                 const SizedBox(height: 32),
//                 _buildRecentScansSection(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildScanButton() {
//     return GestureDetector(
//       onTap: controller.goToScan,
//       child: Container(
//         width: double.infinity,
//         height: 180,
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.qr_code_scanner,
//                 size: 48,
//                 color: Colors.red,
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Scan Barcode',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentScansSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Recent Scans',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             TextButton(
//               onPressed: controller.goToHistory,
//               child: const Text(
//                 'View All',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Obx(() {
//           if (controller.isLoading.value) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }

//           if (controller.recentScans.isEmpty) {
//             return _buildEmptyState();
//           }

//           return ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: controller.recentScans.length,
//             itemBuilder: (context, index) {
//               final scan = controller.recentScans[index];
//               return _buildScanItem(scan.id, scan.timestamp, 
//                 scan.barcodes.isNotEmpty ? scan.barcodes.first.value : 'No barcode data',
//                 scan.barcodes.isNotEmpty ? scan.barcodes.first.format : 'Unknown');
//             },
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildEmptyState() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 32),
//       width: double.infinity,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.qr_code_scanner,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No recent scans',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the scan button to get started',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildScanItem(String id, DateTime timestamp, String value, String format) {
//     final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
//     IconData iconData;
//     if (format.contains('QR')) {
//       iconData = Icons.qr_code;
//     } else if (format.contains('EAN') || format.contains('UPC')) {
//       iconData = Icons.shopping_cart;
//     } else if (format.contains('CODE_128') || format.contains('CODE_39')) {
//       iconData = Icons.inventory;
//     } else {
//       iconData = Icons.qr_code_scanner;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: () => controller.goToScanDetails(id),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   iconData,
//                   color: Colors.red,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       value,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       dateFormat.format(timestamp),
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.arrow_forward_ios,
//                 size: 16,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }