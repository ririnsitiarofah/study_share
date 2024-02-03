import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatelessWidget {
  ScanPage({super.key});

  final _cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Scanner'),
        actions: [
          IconButton(
            iconSize: 32,
            onPressed: _cameraController.toggleTorch,
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32,
            onPressed: _cameraController.switchCamera,
          )
        ],
      ),
      body: MobileScanner(
        controller: _cameraController,
        onDetect: (barcodeCapture) {
          print(barcodeCapture.raw);
        },
      ),
    );
  }
}
