import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fatique_aps/pages/preview_predict.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIdx = 0;
  bool _isProcessing = false;
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera tidak tersedia')),
          );
        }
        return;
      }

      // Select back camera
      _selectedCameraIdx = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIdx == -1) _selectedCameraIdx = 0;

      _onNewCameraSelected(_cameras![_selectedCameraIdx]);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2 || _isProcessing) {
      return;
    }

    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras!.length;
    _onNewCameraSelected(_cameras![_selectedCameraIdx]);
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _controller!.takePicture();

      // Fix orientation issue by processing the image
      final File processedFile = await _fixImageOrientation(File(file.path));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreviewPredictPage(imageFile: processedFile),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Fix image orientation for proper face detection
  Future<File> _fixImageOrientation(File imageFile) async {
    try {
      debugPrint('Processing camera image...');
      // Read the image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // Check camera type
      final isFrontCamera =
          _cameras![_selectedCameraIdx].lensDirection ==
          CameraLensDirection.front;

      // Only flip horizontal for front camera to remove mirror effect
      // No rotation needed - keep original orientation
      if (isFrontCamera) {
        image = img.flipHorizontal(image);
        debugPrint('Front camera: flipped horizontally');
      } else {
        debugPrint('Back camera: no transformation needed');
      }

      // Save with reasonable quality (85% is good balance)
      final directory = await getTemporaryDirectory();
      final targetPath = path.join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}_fixed.jpg',
      );
      final fixedFile = File(targetPath);
      await fixedFile.writeAsBytes(img.encodeJpg(image, quality: 85));

      debugPrint('Image saved: $targetPath (${image.width}x${image.height})');
      return fixedFile;
    } catch (e) {
      debugPrint('Error fixing orientation: $e');
      return imageFile; // Return original if processing fails
    }
  }

  int _getQuarterTurns() {
    switch (_deviceOrientation) {
      case DeviceOrientation.landscapeLeft:
        return 1;
      case DeviceOrientation.landscapeRight:
        return 3;
      case DeviceOrientation.portraitDown:
        return 2;
      case DeviceOrientation.portraitUp:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // Camera Preview
                Center(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      // Update device orientation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final newOrientation =
                            orientation == Orientation.portrait
                            ? DeviceOrientation.portraitUp
                            : DeviceOrientation.landscapeLeft;
                        if (_deviceOrientation != newOrientation) {
                          setState(() => _deviceOrientation = newOrientation);
                        }
                      });

                      return RotatedBox(
                        quarterTurns: _getQuarterTurns(),
                        child: CameraPreview(_controller!),
                      );
                    },
                  ),
                ),

                // Top Controls
                Positioned(
                  top: 40,
                  left: 16,
                  child: _buildControlButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: _buildControlButton(
                    icon: Icons.flip_camera_ios_outlined,
                    onPressed: _switchCamera,
                  ),
                ),

                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }
}
