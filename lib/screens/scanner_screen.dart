import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
    ],
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? barcodeValue = barcodes.first.rawValue;
    if (barcodeValue == null || barcodeValue.isEmpty) return;

    _hasScanned = true;
    HapticFeedback.mediumImpact();
    _controller.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(barcodeScanned: barcodeValue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 280,
      height: 140,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scanner un code-barres',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final hasTorch =
                  state.torchState != TorchState.unavailable;
              if (!hasTorch) return const SizedBox.shrink();
              final isOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: isOn ? Colors.yellow : Colors.white,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded,
                color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: 20),
                      const Text(
                        'Erreur camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.errorDetails?.message ??
                            'Impossible d\'acceder a la camera.',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Colors.white54),
                        ),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          CustomPaint(
            painter: _ScannerOverlayPainter(scanWindow: scanWindow),
            child: const SizedBox.expand(),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Placez le code-barres dans le cadre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Le scan se declenchera automatiquement',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  _ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.55);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cornerPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            scanWindow, const Radius.circular(12))),
    );
    canvas.drawPath(backgroundPath, overlayPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      borderPaint,
    );

    const double cornerLength = 28;
    final Rect r = scanWindow;
    const Radius rad = Radius.circular(12);

    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + cornerLength)
        ..lineTo(r.left, r.top + rad.y)
        ..arcToPoint(Offset(r.left + rad.x, r.top), radius: rad)
        ..lineTo(r.left + cornerLength, r.top),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(r.right - cornerLength, r.top)
        ..lineTo(r.right - rad.x, r.top)
        ..arcToPoint(Offset(r.right, r.top + rad.y), radius: rad)
        ..lineTo(r.right, r.top + cornerLength),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom - cornerLength)
        ..lineTo(r.left, r.bottom - rad.y)
        ..arcToPoint(Offset(r.left + rad.x, r.bottom), radius: rad)
        ..lineTo(r.left + cornerLength, r.bottom),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(r.right, r.bottom - cornerLength)
        ..lineTo(r.right, r.bottom - rad.y)
        ..arcToPoint(Offset(r.right - rad.x, r.bottom), radius: rad)
        ..lineTo(r.right - cornerLength, r.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}