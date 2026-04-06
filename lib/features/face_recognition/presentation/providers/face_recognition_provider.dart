import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/services/face_detector_service.dart';
import '../../domain/services/tflite_service.dart';
import '../../data/repositories/face_repository_impl.dart';
import '../../data/models/requests/face_register_request.dart';
import '../../data/models/requests/face_verify_request.dart';
import '../../../../core/base/result.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'face_recognition_state.dart';

part 'face_recognition_provider.g.dart';

@riverpod
class FaceRecognitionNotifier extends _$FaceRecognitionNotifier {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  bool _isProcessingFrame = false;
  CameraImage? _lastImage;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  FaceRecognitionState build() {
    ref.onDispose(() {
      _cameraController?.dispose();
    });
    return const FaceRecognitionState();
  }

  Future<void> initialize() async {
    state = state.copyWith(isInitializing: true, error: null);

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Camera permission denied',
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          isInitializing: false,
          error: 'No cameras found',
        );
        return;
      }

      _cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        _cameraDescription!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await ref.read(tfliteServiceProvider).init();

      if (ref.mounted) {
        state = state.copyWith(isInitializing: false);
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(isInitializing: false, error: e.toString());
      }
    }
  }

  void startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((image) async {
      _lastImage = image;
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      try {
        final inputImage = _processCameraImage(image);
        if (inputImage == null) return;

        if (!ref.mounted) return;
        final faces = await ref
            .read(faceDetectorServiceProvider)
            .detectFaces(inputImage);

        if (!ref.mounted) return;
        state = state.copyWith(faces: faces);
      } catch (e) {
        if (ref.mounted) {
          debugPrint('Detection error: $e');
        }
      } finally {
        if (ref.mounted) {
          _isProcessingFrame = false;
        }
      }
    });
  }

  Future<void> captureAndProcess({required bool isRegistration}) async {
    if (state.faces.isEmpty || _lastImage == null) {
      if (ref.mounted) {
        state = state.copyWith(error: 'No face detected');
      }
      return;
    }

    // Clear previous error before starting a new process
    if (ref.mounted) {
      state = state.copyWith(error: null);
    }

    final image = _lastImage!;
    await processFrame(image, isRegistration: isRegistration);
  }

  InputImage? _processCameraImage(CameraImage image) {
    if (_cameraController == null || _cameraDescription == null) return null;

    // 1. Get Rotation
    final sensorOrientation = _cameraDescription!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (_cameraDescription!.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // 2. Get Format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format depending on platform
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // Since format is constrained to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future<void> processFrame(
    CameraImage image, {
    required bool isRegistration,
  }) async {
    if (state.isProcessing || state.success) return;

    // Clear previous error and set processing
    if (ref.mounted) {
      state = state.copyWith(isProcessing: true, error: null);
    }

    try {
      final inputImage = _processCameraImage(image);
      if (inputImage == null) {
        if (ref.mounted) {
          state = state.copyWith(
            isProcessing: false,
            error: 'Failed to process image',
          );
        }
        return;
      }

      if (!ref.mounted) return;

      final faces = await ref
          .read(faceDetectorServiceProvider)
          .detectFaces(inputImage);

      if (!ref.mounted) return;

      if (faces.isEmpty) {
        state = state.copyWith(isProcessing: false, error: 'No face detected');
        return;
      }

      final face = faces.first;
      if (!ref.mounted) return;

      final embeddings = await ref
          .read(tfliteServiceProvider)
          .extractEmbeddings(image, face);

      if (!ref.mounted) return;

      if (embeddings.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to extract embeddings',
        );
        return;
      }

      if (isRegistration) {
        final authState = ref.read(authProvider);
        final user = authState.value;

        if (user == null) {
          if (ref.mounted) {
            state = state.copyWith(
              isProcessing: false,
              error: 'User not logged in',
            );
          }
          return;
        }

        if (!ref.mounted) return;

        final result = await ref
            .read(faceRepositoryProvider)
            .registerFace(
              FaceRegisterRequest(userId: user.id, embedding: embeddings),
            );

        if (!ref.mounted) return;

        result.when(
          success: (response, message) {
            if (ref.mounted) {
              state = state.copyWith(isProcessing: false, success: true);
            }
          },
          failure: (error, stackTrace) {
            if (ref.mounted) {
              state = state.copyWith(
                isProcessing: false,
                error: error.toString(),
              );
            }
          },
        );
      } else {
        if (!ref.mounted) return;

        final result = await ref
            .read(faceRepositoryProvider)
            .verifyFace(FaceVerifyRequest(embedding: embeddings));

        if (!ref.mounted) return;

        result.when(
          success: (response, message) {
            if (ref.mounted) {
              if (response.match) {
                state = state.copyWith(isProcessing: false, success: true);
              } else {
                state = state.copyWith(
                  isProcessing: false,
                  error: 'Face not matched',
                );
              }
            }
          },
          failure: (error, stackTrace) {
            if (ref.mounted) {
              state = state.copyWith(
                isProcessing: false,
                error: error.toString(),
              );
            }
          },
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(isProcessing: false, error: e.toString());
      }
    }
  }

  void reset() {
    state = const FaceRecognitionState();
  }

  void stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  CameraController? get controller => _cameraController;
}
