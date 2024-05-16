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
          ValueListenableBuilder(
            valueListenable: _cameraController,
            builder: (context, state, child) {
              return IconButton(
                iconSize: 32,
                onPressed: _cameraController.toggleTorch,
                color: Colors.white,
                icon: switch (state.torchState) {
                  TorchState.off => const Icon(
                      Icons.flash_off,
                      color: Colors.grey,
                    ),
                  TorchState.on => const Icon(
                      Icons.flash_on,
                      color: Colors.yellow,
                    ),
                  TorchState.auto => const Icon(
                      Icons.flash_auto,
                      color: Colors.yellow,
                    ),
                  TorchState.unavailable => const SizedBox(),
                },
              );
            },
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
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
