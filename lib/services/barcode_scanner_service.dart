import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  static String formatBarcodeType(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.upcA:
        return 'UPC-A';
      case BarcodeFormat.upcE:
        return 'UPC-E';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.qrCode:
        return 'QR Code';
      default:
        return format.name;
    }
  }
}