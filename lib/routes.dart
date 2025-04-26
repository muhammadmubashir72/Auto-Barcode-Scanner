// routes.dart
import 'package:get/get.dart';
import 'package:scanner_app/modules/barcode_home/binding/barcode_home_binding.dart';
import 'package:scanner_app/modules/history/binding/history_binding.dart';
import 'package:scanner_app/modules/history/views/history_view.dart';
import 'package:scanner_app/modules/scan_details/binding/scan_details_binding.dart';
import 'package:scanner_app/modules/scan_details/views/scan_details_view.dart';
import 'package:scanner_app/modules/barcode_home/views/barcode_home_view.dart';
import 'package:scanner_app/modules/scanner/binding/mobile_scanner_binding.dart';
import 'package:scanner_app/modules/scanner/views/mobile_scanner_view.dart';

class AppRoutes {
  static final routes = [
    GetPage(
      name: '/',
      page: () => const BarcodeHomeView(),
      binding: BarcodeHomeBinding(),
    ),
    GetPage(
      name: '/scanner',
      page: () => const MobileScannerView(),
      binding: MobileScannerBinding(),
    ),
    GetPage(
      name: '/scan_details',
      page: () => const ScanDetailsView(),
      binding: ScanDetailsBinding(),
    ),
    GetPage(
      name: '/history',
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
  ];
}

// import 'package:get/get.dart';
// import 'package:scanner_app/modules/barcode_home/views/barcode_home_view.dart';
// import 'package:scanner_app/modules/history/controllers/history_controller.dart';
// import 'package:scanner_app/modules/history/views/history_view.dart';
// import 'package:scanner_app/modules/scan_details/controllers/scan_details_controller.dart';
// import 'package:scanner_app/modules/scan_details/views/scan_details_view.dart';
// import 'package:scanner_app/modules/scanner/binding/mobile_scanner_binding.dart';
// import 'package:scanner_app/modules/scanner/views/mobile_scanner_view.dart';

// class AppRoutes {
//   static final routes = [
//     GetPage(
//       name: '/barcode_home',
//       page: () => const BarcodeHomeView(),
//     ),
//     GetPage(
//       name: '/history',
//       page: () => const HistoryView(),
//       binding: BindingsBuilder(() {
//         Get.lazyPut<HistoryController>(() => HistoryController());
//       }),
//     ),
//     GetPage(
//       name: '/scan_details',
//       page: () => const ScanDetailsView(),
//       binding: BindingsBuilder(() {
//         Get.lazyPut<ScanDetailsController>(() => ScanDetailsController());
//       }),
//     ),
//     GetPage(
//       name: '/scanner',
//       page: () => const MobileScannerView(),
//       binding: MobileScannerBinding(),
//     ),
//     // Keep the old scanner route for backward compatibility
//     GetPage(
//       name: '/scan',
//       page: () => const MobileScannerView(),
//       binding: MobileScannerBinding(),
//     ),
//   ];
// }