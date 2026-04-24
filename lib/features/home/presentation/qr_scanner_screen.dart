import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanCompleted = false;
  final TextEditingController _manualController = TextEditingController();
  
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, 
  );

  @override
  void dispose() {
    _cameraController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: Stack(
        children: [
          // Evitar que la cámara secuestre toques de pantalla
          IgnorePointer(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
              if (!_isScanCompleted) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _isScanCompleted = true; 
                    Navigator.pop(context, barcode.rawValue!);
                    break;
                  }
                }
              }
            },
          ),
        ),

          // Botón Flotante Solitario (Diseño original exacto)
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ingresa manualmente:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          decoration: InputDecoration(
                            hintText: 'Ej. 8fJsd82...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          if (_manualController.text.trim().isNotEmpty) {
                            Navigator.pop(context, _manualController.text.trim());
                          }
                        },
                        child: const Icon(Icons.search, color: Colors.white),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
