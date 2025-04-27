// data/utils/scan_utils.dart
import 'package:scanner_app/data/models/scan_result.dart';

class ScanUtils {
  static bool isUrl(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        RegExp(r'^(www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(text);
  }

  static bool isPhoneNumber(String text) {
    return text.startsWith('tel:') ||
        RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$').hasMatch(text);
  }

  static bool isWifi(String text) {
    return text.startsWith('WIFI:');
  }

  static bool isVCard(String text) {
    return text.startsWith('BEGIN:VCARD');
  }

  static bool isQRCode(String format) {
    return format.toLowerCase().contains('qr');
  }

  static bool isBarcode(String format) {
    return !format.toLowerCase().contains('qr') &&
        format.toLowerCase().contains('barcodeformat');
  }

  static String getScanType(BarcodeData barcode) {
    final value = barcode.value;
    final format = barcode.format;
    if (isWifi(value)) return 'wifi';
    if (isUrl(value)) return 'url';
    if (isPhoneNumber(value)) return 'phone';
    if (isVCard(value)) return 'vcard';
    if (isQRCode(format)) return 'qr';
    if (isBarcode(format)) return 'barcode';
    return 'other';
  }
}