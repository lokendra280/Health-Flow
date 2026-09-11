import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/ads/config/rewarded_ad_service.dart';
import 'package:habitflow/features/food_tracking/widgets/food_scan_result.dart';

class FoodCameraScreen extends ConsumerStatefulWidget {
  final DateTime day;
  const FoodCameraScreen({super.key, required this.day});

  @override
  ConsumerState<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends ConsumerState<FoodCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  FlashMode _flashMode = FlashMode.off;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't access the camera: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Release the camera when backgrounded, re-init on resume — avoids
    // holding the camera hardware while the app isn't visible.
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initFuture = _initCamera();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await controller.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;

      // Gate the actual food logging behind a rewarded ad. Failing to load
      // fails OPEN (still lets them log) so a monetization hiccup never
      // blocks a core feature — flip this if you'd rather hard-block instead.
      final adResult = await RewardedAdService.instance.show();
      if (!mounted) return;

      if (adResult == RewardedAdResult.dismissedWithoutReward) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch the full ad to log this meal.'),
          ),
        );
        return; // stay on the camera screen so they can retry
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => FoodScanResultSheet(
          image: File(file.path),
          day: widget.day,
        ),
      );

      // Once the scan sheet closes (whether items were added or the
      // user dismissed it), return to whatever screen opened the camera.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't capture photo: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_error != null) {
            return _ErrorView(
                message: _error!, onClose: () => Navigator.of(context).pop());
          }

          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),

              // Top bar: close + flash toggle
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      _RoundIconButton(
                        icon: _flashMode == FlashMode.off
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        onTap: _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ),

              // Framing guide — purely visual, helps the user center the plate.
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Bottom capture bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28, top: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _capturing
                              ? 'Preparing your scan…'
                              : 'Center your food in the frame',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _capturing ? null : _capture,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: _capturing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Container(
                                      width: 58,
                                      height: 58,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorView({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClose,
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
