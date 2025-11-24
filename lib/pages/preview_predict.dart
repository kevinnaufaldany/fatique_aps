import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fatique_aps/pages/result_page.dart';

class PreviewPredictPage extends StatefulWidget {
  final File imageFile;

  const PreviewPredictPage({super.key, required this.imageFile});

  @override
  State<PreviewPredictPage> createState() => _PreviewPredictPageState();
}

class _PreviewPredictPageState extends State<PreviewPredictPage> {
  bool _isPredicting = false;

  Future<void> _predictImage() async {
    setState(() => _isPredicting = true);

    try {
      // API endpoint
      const String apiUrl = 'https://mowzaaaa-fatigue-api.hf.space/predict';

      // Create multipart request - send original image (no compression)
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add image file with correct field name and content type
      // Sesuai dengan Python code yang berhasil: files = {'file': (image_path, f, 'image/jpeg')}
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Changed from 'image' to 'file'
          widget.imageFile.path,
          filename: widget.imageFile.path.split('/').last,
        ),
      );

      debugPrint('Mengirim request ke: $apiUrl');
      debugPrint('File path: ${widget.imageFile.path}');

      // Send request with timeout (30 seconds)
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Request timeout - API tidak merespons dalam 30 detik',
          );
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response
        var jsonResponse = json.decode(response.body);
        debugPrint('Hasil Prediksi (JSON): $jsonResponse');

        // Check if response has error message
        if (jsonResponse.containsKey('error')) {
          throw Exception('API Error: ${jsonResponse['error']}');
        }

        // NEW FORMAT: Check if response has 'results' field (new API format)
        // Format: {face_count: 1, message: 'Sukses', results: [{bounding_box: [...], confidence: 0.99, prediction: 'Fatigue'}]}
        if (jsonResponse.containsKey('results') &&
            jsonResponse['results'] is List) {
          final List results = jsonResponse['results'];
          if (results.isNotEmpty) {
            // Create result object with all_results and API metadata
            final resultData = <String, dynamic>{
              'all_results': results,
              'face_count': jsonResponse['face_count'] ?? results.length,
              'message': jsonResponse['message'] ?? 'Success',
              // Add first result fields for backward compatibility
              'prediction': results[0]['prediction'],
              'confidence': results[0]['confidence'],
              'bounding_box': results[0]['bounding_box'],
            };

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultPage(
                    imageFile:
                        widget.imageFile, // Gunakan gambar original yang dikirim ke API
                    result: resultData,
                  ),
                ),
              );
            }
          } else {
            throw Exception('Tidak ada wajah terdeteksi dalam gambar');
          }
        }
        // OLD FORMAT: Check if response has required fields (old API format)
        else if (jsonResponse.containsKey('prediction') &&
            jsonResponse.containsKey('bounding_box')) {
          if (mounted) {
            // Navigate to result page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResultPage(
                  imageFile:
                      widget.imageFile, // Gunakan gambar original yang dikirim ke API
                  result: jsonResponse,
                ),
              ),
            );
          }
        } else {
          throw Exception(
            'Format respons tidak dikenal: ${jsonResponse.toString()}',
          );
        }
      } else if (response.statusCode == 400) {
        // Parse error message for 400 status
        try {
          var errorResponse = json.decode(response.body);
          String errorMsg = errorResponse['error'] ?? 'Bad Request';
          throw Exception('API Error (400): $errorMsg');
        } catch (e) {
          throw Exception('API Error (400): ${response.body}');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Prediction error: $e');
      if (mounted) {
        // Show more detailed error message
        String errorMessage = 'Error: $e';
        if (e.toString().contains('Tidak ada wajah') ||
            e.toString().contains('No face')) {
          errorMessage =
              'Tidak ada wajah terdeteksi. Pastikan foto menampilkan wajah dengan jelas.';
        } else if (e.toString().contains('400')) {
          errorMessage =
              'Foto tidak valid atau tidak ada wajah terdeteksi.\n\nTips:\n• Pastikan wajah terlihat jelas\n• Gunakan pencahayaan yang cukup\n• Foto tidak blur atau terlalu gelap';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPredicting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isPredicting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Preview & Predict',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(widget.imageFile, fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          // Predict Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPredicting ? null : _predictImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isPredicting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Prediksi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_isPredicting) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Memprediksi. Mohon tunggu sebentar.',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
