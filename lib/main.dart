import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scanner_app/data/services/scanner_service.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:scanner_app/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for better performance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Initialize services
    await Get.putAsync(() => StorageService().init());
    Get.put(ScannerService());
  } catch (e) {
    print('Error initializing services: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Barcode Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      getPages: AppRoutes.routes,
      initialRoute: '/barcode_home',
      defaultTransition: Transition.cupertino,
    );
  }
}