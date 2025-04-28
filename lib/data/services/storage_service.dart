import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:sqflite/sqflite.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find<StorageService>();

  late Database _database;
  late String _imagesDir;

  final isInitialized = false.obs;

  Future<StorageService> init() async {
    try {
      // Initialize database
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'barcode_scanner.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE scans(id TEXT PRIMARY KEY, timestamp INTEGER, data TEXT)',
          );
        },
      );

      // Create directory for storing images
      final appDir = await getApplicationDocumentsDirectory();
      _imagesDir = join(appDir.path, 'scan_images');
      final dir = Directory(_imagesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      isInitialized.value = true;
      print('StorageService initialized successfully');
      return this;
    } catch (e) {
      print('Error initializing storage service: $e');
      rethrow;
    }
  }

  Future<String> saveImage(File imageFile) async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = join(_imagesDir, fileName);
      await imageFile.copy(savedImagePath);
      print('Image saved to: $savedImagePath');
      return savedImagePath;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  Future<void> saveScanResult(ScanResult scanResult) async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      final data = scanResult.toJson();
      print('Saving scan result: $data');

      await _database.insert(
        'scans',
        {
          'id': scanResult.id,
          'timestamp': scanResult.timestamp.millisecondsSinceEpoch,
          'data': data,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Saved scan result with ID: ${scanResult.id}');
    } catch (e) {
      print('Error saving scan result: $e');
      rethrow;
    }
  }

  Future<List<ScanResult>> getAllScans() async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      final List<Map<String, dynamic>> maps = await _database.query('scans', orderBy: 'timestamp DESC');
      print('Retrieved ${maps.length} scans from database');

      return List.generate(maps.length, (i) {
        try {
          return ScanResult.fromJson(maps[i]['data'] as String);
        } catch (e) {
          print('Error parsing scan result at index $i: $e');
          print('Data: ${maps[i]['data']}');
          return ScanResult(
            id: maps[i]['id'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp'] as int),
            barcodes: [],
          );
        }
      });
    } catch (e) {
      print('Error getting all scans: $e');
      return [];
    }
  }

  Future<ScanResult?> getScanById(String id) async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      print('Getting scan with ID: $id');
      final List<Map<String, dynamic>> maps = await _database.query(
        'scans',
        where: 'id = ?',
        whereArgs: [id],
      );

      print('Query returned ${maps.length} results');

      if (maps.isEmpty) {
        print('No scan found with ID: $id');
        final directResults = await _database.rawQuery('SELECT id FROM scans');
        print('Available scan IDs: ${directResults.map((e) => e['id']).toList()}');
        return null;
      }

      try {
        final data = maps.first['data'] as String;
        print('Found scan data: $data');
        final result = ScanResult.fromJson(data);
        print('Parsed scan result: ${result.id}');
        return result;
      } catch (e) {
        print('Error parsing scan result: $e');
        print('Raw data: ${maps.first['data']}');
        return null;
      }
    } catch (e) {
      print('Error getting scan by ID: $e');
      return null;
    }
  }

  Future<void> deleteScan(String id) async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      // Get scan to delete associated image
      final scan = await getScanById(id);
      if (scan != null && scan.imagePath != null) {
        final imageFile = File(scan.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('Deleted image: ${scan.imagePath}');
        }
      }

      // Delete from database
      final deletedRows = await _database.delete(
        'scans',
        where: 'id = ?',
        whereArgs: [id],
      );

      print('Deleted $deletedRows rows for scan ID: $id');
    } catch (e) {
      print('Error deleting scan: $e');
      rethrow;
    }
  }

  Future<void> clearAllScans() async {
    if (!isInitialized.value) {
      throw Exception('StorageService not initialized');
    }

    try {
      // Delete all images in the images directory
      final dir = Directory(_imagesDir);
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: false)) {
          if (entity is File) {
            await entity.delete();
            print('Deleted image: ${entity.path}');
          }
        }
      }

      // Delete all scans from database
      final deletedRows = await _database.delete('scans');
      print('Deleted $deletedRows scan records from database');
    } catch (e) {
      print('Error clearing all scans: $e');
      rethrow;
    }
  }
}

// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:sqflite/sqflite.dart';

// class StorageService extends GetxService {
//   static StorageService get to => Get.find<StorageService>();
  
//   late Database _database;
//   late String _imagesDir;
  
//   final isInitialized = false.obs;

//   Future<StorageService> init() async {
//     try {
//       // Initialize database
//       final documentsDirectory = await getApplicationDocumentsDirectory();
//       final path = join(documentsDirectory.path, 'barcode_scanner.db');
      
//       _database = await openDatabase(
//         path,
//         version: 1,
//         onCreate: (Database db, int version) async {
//           await db.execute(
//             'CREATE TABLE scans(id TEXT PRIMARY KEY, timestamp INTEGER, data TEXT)',
//           );
//         },
//       );
      
//       // Create directory for storing images
//       final appDir = await getApplicationDocumentsDirectory();
//       _imagesDir = join(appDir.path, 'scan_images');
//       final dir = Directory(_imagesDir);
//       if (!await dir.exists()) {
//         await dir.create(recursive: true);
//       }
      
//       isInitialized.value = true;
//       return this;
//     } catch (e) {
//       print('Error initializing storage service: $e');
//       rethrow;
//     }
//   }

//   Future<String> saveImage(File imageFile) async {
//     if (!isInitialized.value) {
//       throw Exception('StorageService not initialized');
//     }
    
//     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final savedImagePath = join(_imagesDir, fileName);
//     await imageFile.copy(savedImagePath);
//     return savedImagePath;
//   }

//   Future<void> saveScanResult(ScanResult scanResult) async {
//     if (!isInitialized.value) {
//       throw Exception('StorageService not initialized');
//     }
    
//     try {
//       final data = scanResult.toJson();
//       print('Saving scan result: $data');
      
//       await _database.insert(
//         'scans',
//         {
//           'id': scanResult.id,
//           'timestamp': scanResult.timestamp.millisecondsSinceEpoch,
//           'data': data,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
      
//       print('Saved scan result with ID: ${scanResult.id}');
//     } catch (e) {
//       print('Error saving scan result: $e');
//       rethrow;
//     }
//   }

//   Future<List<ScanResult>> getAllScans() async {
//     if (!isInitialized.value) {
//       throw Exception('StorageService not initialized');
//     }
    
//     try {
//       final List<Map<String, dynamic>> maps = await _database.query('scans', orderBy: 'timestamp DESC');
//       print('Retrieved ${maps.length} scans from database');
      
//       return List.generate(maps.length, (i) {
//         try {
//           return ScanResult.fromJson(maps[i]['data'] as String);
//         } catch (e) {
//           print('Error parsing scan result at index $i: $e');
//           print('Data: ${maps[i]['data']}');
//           // Return a placeholder scan result to avoid crashing the app
//           return ScanResult(
//             id: maps[i]['id'] as String,
//             timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp'] as int),
//             barcodes: [],
//           );
//         }
//       });
//     } catch (e) {
//       print('Error getting all scans: $e');
//       return [];
//     }
//   }

//   Future<ScanResult?> getScanById(String id) async {
//     if (!isInitialized.value) {
//       throw Exception('StorageService not initialized');
//     }
    
//     try {
//       print('Getting scan with ID: $id');
//       print('SQL Query: SELECT * FROM scans WHERE id = "$id"');
//       final List<Map<String, dynamic>> maps = await _database.query(
//         'scans',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
    
//       print('Query returned ${maps.length} results');
    
//       if (maps.isEmpty) {
//         print('No scan found with ID: $id');
      
//         // Try a direct query to check if the scan exists
//         final directResults = await _database.rawQuery('SELECT id FROM scans');
//         print('Available scan IDs: ${directResults.map((e) => e['id']).toList()}');
      
//         return null;
//       }
    
//       try {
//         final data = maps.first['data'] as String;
//         print('Found scan data: $data');
//         final result = ScanResult.fromJson(data);
//         print('Parsed scan result: ${result.id}');
//         return result;
//       } catch (e) {
//         print('Error parsing scan result: $e');
//         print('Raw data: ${maps.first['data']}');
//         return null;
//       }
//     } catch (e) {
//       print('Error getting scan by ID: $e');
//       return null;
//     }
//   }

//   Future<void> deleteScan(String id) async {
//     if (!isInitialized.value) {
//       throw Exception('StorageService not initialized');
//     }
    
//     try {
//       // Get scan to delete associated image
//       final scan = await getScanById(id);
//       if (scan != null && scan.imagePath != null) {
//         final imageFile = File(scan.imagePath!);
//         if (await imageFile.exists()) {
//           await imageFile.delete();
//         }
//       }
      
//       // Delete from database
//       final deletedRows = await _database.delete(
//         'scans',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
      
//       print('Deleted $deletedRows rows for scan ID: $id');
//     } catch (e) {
//       print('Error deleting scan: $e');
//       rethrow;
//     }
//   }
// }