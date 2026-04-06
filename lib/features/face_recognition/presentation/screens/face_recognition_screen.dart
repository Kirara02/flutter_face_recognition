import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/face_recognition_provider.dart';
import '../providers/face_recognition_state.dart';
import '../../../../core/extensions/context_ext.dart';

class FaceRecognitionScreen extends ConsumerStatefulWidget {
  final bool isRegistration;

  const FaceRecognitionScreen({super.key, this.isRegistration = false});

  @override
  ConsumerState<FaceRecognitionScreen> createState() =>
      _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends ConsumerState<FaceRecognitionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(faceRecognitionProvider.notifier).initialize().then((_) {
        ref.read(faceRecognitionProvider.notifier).startDetection();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(faceRecognitionProvider.notifier);
    final controller = notifier.controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      notifier.stopCamera(); // Use the notifier's specialized method
    } else if (state == AppLifecycleState.resumed) {
      notifier.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceRecognitionProvider);
    final notifier = ref.read(faceRecognitionProvider.notifier);

    ref.listen<FaceRecognitionState>(faceRecognitionProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        if (error == 'Face not matched' || error == 'No face detected') {
          final message = error == 'Face not matched'
              ? context.l10n.faceRecognition.errorNotMatched
              : context.l10n.faceRecognition.errorNoFace;
          context.showSnackBar(message, isError: true);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isRegistration
              ? context.l10n.faceRecognition.registerTitle
              : context.l10n.faceRecognition.verifyTitle,
        ),
      ),
      body: Stack(
        children: [
          if (state.isInitializing)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null &&
              !state.isProcessing &&
              (notifier.controller == null ||
                  !notifier.controller!.value.isInitialized))
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => notifier.initialize(),
                    child: Text(context.l10n.common.retry),
                  ),
                ],
              ),
            )
          else if (notifier.controller != null &&
              notifier.controller!.value.isInitialized)
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: notifier.controller!.value.previewSize!.height,
                    height: notifier.controller!.value.previewSize!.width,
                    child: CameraPreview(notifier.controller!),
                  ),
                ),
              ),
            ),

          // Loading Overlay
          if (state.isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.faceRecognition.processing,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Instruction Text
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  state.faces.isEmpty
                      ? context.l10n.faceRecognition.instructionNoFace
                      : context.l10n.faceRecognition.instructionFaceDetected,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Action Button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: state.isProcessing || state.success
                    ? null
                    : () async {
                        notifier.captureAndProcess(
                          isRegistration: widget.isRegistration,
                        );
                      },
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),

          // Success Dialog
          if (state.success)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isRegistration
                          ? context.l10n.faceRecognition.successRegister
                          : context.l10n.faceRecognition.successVerify,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text(context.l10n.faceRecognition.goBack),
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

// Class removed as requested
