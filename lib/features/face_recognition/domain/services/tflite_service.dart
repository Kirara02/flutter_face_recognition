import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

part 'tflite_service.g.dart';

class TFLiteService {
  Interpreter? _interpreter;
  static const int _inputSize = 112;

  Future<void> init() async {
    if (_interpreter != null) return;
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );
      debugPrint('TFLite Model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load TFLite Model: $e');
    }
  }

  Future<List<double>> extractEmbeddings(CameraImage image, Face face) async {
    if (_interpreter == null) await init();

    // 1. Convert CameraImage to img.Image
    final img.Image? originalImage = _convertCameraImage(image);
    if (originalImage == null) return [];

    // 2. Crop Face
    final faceRect = face.boundingBox;
    
    // Ensure crop is within image bounds
    final cropX = faceRect.left.toInt().clamp(0, originalImage.width);
    final cropY = faceRect.top.toInt().clamp(0, originalImage.height);
    final cropW = faceRect.width.toInt().clamp(0, originalImage.width - cropX);
    final cropH = faceRect.height.toInt().clamp(0, originalImage.height - cropY);

    if (cropW <= 0 || cropH <= 0) return [];

    final croppedFace = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 3. Resize to model input size (112x112)
    final resizedFace = img.copyResize(
      croppedFace,
      width: _inputSize,
      height: _inputSize,
    );

    // 4. Preprocess (Normalize)
    final input = _imageToByteListFloat32(resizedFace);

    // 5. Run inference
    final output = List<double>.filled(192, 0).reshape([1, 192]);
    _interpreter?.run(input, output);

    return List<double>.from(output[0]);
  }

  dynamic _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
    var bufferIndex = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // Normalize to [-1, 1] as usually required by MobileFaceNet
        convertedBytes[bufferIndex++] = (pixel.r - 127.5) / 128.0;
        convertedBytes[bufferIndex++] = (pixel.g - 127.5) / 128.0;
        convertedBytes[bufferIndex++] = (pixel.b - 127.5) / 128.0;
      }
    }
    return convertedBytes.reshape([1, _inputSize, _inputSize, 3]);
  }

  img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToImage(image);
      }
    } catch (e) {
      debugPrint("Conversion Error: $e");
    }
    return null;
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final outImg = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + (1.370705 * (vp - 128))).toInt().clamp(0, 255);
        int g = (yp - (0.337633 * (up - 128)) - (0.698001 * (vp - 128)))
            .toInt()
            .clamp(0, 255);
        int b = (yp + (1.732446 * (up - 128))).toInt().clamp(0, 255);

        outImg.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
    return Platform.isAndroid
        ? img.copyRotate(outImg, angle: 270)
        : img.copyRotate(outImg, angle: 90);
  }

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final outImg = img.Image(width: width, height: height);

    final bytes = image.planes[0].bytes;
    var index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int blue = bytes[index++];
        final int green = bytes[index++];
        final int red = bytes[index++];
        index++; // Alpha/Padding
        outImg.setPixel(x, y, img.ColorRgb8(red, green, blue));
      }
    }
    return Platform.isAndroid
        ? img.copyRotate(outImg, angle: 270)
        : img.copyRotate(outImg, angle: 90);
  }

  img.Image _convertNV21ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final outImg = img.Image(width: width, height: height);
    final bytes = image.planes[0].bytes;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int yp = bytes[yIndex];

        // UV interleaved VU VU... starting after Y plane
        final int uvIndex = (width * height) + (y ~/ 2) * width + (x ~/ 2) * 2;
        
        // Safety check for buffer size
        if (uvIndex + 1 < bytes.length) {
          final int vp = bytes[uvIndex];
          final int up = bytes[uvIndex + 1];

          int r = (yp + (1.370705 * (vp - 128))).toInt().clamp(0, 255);
          int g = (yp - (0.337633 * (up - 128)) - (0.698001 * (vp - 128)))
              .toInt()
              .clamp(0, 255);
          int b = (yp + (1.732446 * (up - 128))).toInt().clamp(0, 255);

          outImg.setPixel(x, y, img.ColorRgb8(r, g, b));
        } else {
           outImg.setPixel(x, y, img.ColorRgb8(yp, yp, yp)); // Fallback to grayscale
        }
      }
    }

    return Platform.isAndroid
        ? img.copyRotate(outImg, angle: 270)
        : img.copyRotate(outImg, angle: 90);
  }

  void dispose() {
    _interpreter?.close();
  }
}

@Riverpod(keepAlive: true)
TFLiteService tfliteService(Ref ref) {
  final service = TFLiteService();
  ref.onDispose(service.dispose);
  return service;
}
