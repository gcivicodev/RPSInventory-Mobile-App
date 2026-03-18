import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Una vista dedicada para escanear códigos de barras.
///
/// Esta vista muestra la cámara y un overlay para guiar al usuario.
/// Proporciona controles para la linterna y la cámara, y devuelve el valor
/// del primer código de barras detectado a la pantalla anterior.
///
/// NOTA: Este código ha sido corregido para ser compatible con la API de
/// mobile_scanner: ^7.0.1 y versiones similares.
class ViewScanner extends StatefulWidget {
  const ViewScanner({super.key});

  @override
  State<ViewScanner> createState() => _ViewScannerState();
}

class _ViewScannerState extends State<ViewScanner> {
  // Controlador para el widget MobileScanner.
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    // El parámetro torchEnabled se usa en esta versión del paquete.
    torchEnabled: false,
  );

  // Flags para manejar el estado de los botones manualmente, ya que
  // .torchState y .cameraFacingState no existen como ValueNotifiers en esta versión.
  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
        backgroundColor: const Color(0xff0088CC),
        foregroundColor: Colors.white,
        actions: [
          // Botón para controlar la linterna (torch)
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white70,
            ),
            tooltip: 'Linterna',
            onPressed: () {
              // Llamamos al método para alternar la linterna
              _scannerController.toggleTorch();
              // Y actualizamos el estado local del icono manualmente
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          // Botón para cambiar de cámara (trasera/frontal)
          // Nota: El cambio de cámara puede no reflejar un ícono diferente
          // sin un ValueNotifier, pero la funcionalidad de cambio sí operará.
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
            tooltip: 'Cambiar Cámara',
            onPressed: () {
              // Llamamos al método para cambiar la cámara
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Widget principal que muestra la vista de la cámara y detecta códigos
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() {
                  _isProcessing = true;
                });
                final String code = barcodes.first.rawValue!;

                Navigator.of(context).pop(code);
              }
            },
          ),
          // Overlay para guiar al usuario
          _buildScannerOverlay(context),
        ],
      ),
    );
  }

  /// Construye un overlay con un recorte en el centro para guiar al usuario
  /// sobre dónde posicionar el código de barras.
  Widget _buildScannerOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 200, // Altura del área de escaneo
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade400, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Apunte la cámara al código de barras',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
