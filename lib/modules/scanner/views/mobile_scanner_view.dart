// modules/scanner/views/mobile_scanner_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/mobile_scanner_controller.dart';

class MobileScannerView extends GetView<CustomScannerController> {
  const MobileScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Barcode',
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
      ),
      body: Obx(() {
        if (!controller.hasPermission.value) {
          return _buildPermissionDenied();
        }
        
        if (!controller.isInitialized.value || controller.cameraController.value == null) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        
        return _buildScannerView();
      }),
    );
  }
  
  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Camera permission denied', style: Get.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Please enable camera permission in settings to use this feature',
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Scanner view
        MobileScanner(
          controller: controller.cameraController.value!,
          onDetect: controller.processDetection,
        ),
        
        // Custom overlay
        CustomPaint(
          painter: ScannerOverlayPainter(),
          child: Container(),
        ),
        
        // Scanning instructions
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Position barcode within the frame for scanning',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: controller.pickImageFromGallery,
                ),
                Obx(() => _buildActionButton(
                  icon: controller.torchState.value == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                  label: 'Flash',
                  onTap: controller.toggleTorch,
                )),
              ],
            ),
          ),
        ),
        
        // Loading overlay
        Obx(() {
          if (controller.isProcessing.value) {
            return Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = 250;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;
    
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanArea = Rect.fromLTRB(left, top, right, bottom);
    final scanAreaPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanArea,
        const Radius.circular(12),
      ));
    
    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(138)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanAreaPath,
    );
    
    canvas.drawPath(finalPath, backgroundPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanArea,
        const Radius.circular(12),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
