import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ResultPage extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> result;

  const ResultPage({super.key, required this.imageFile, required this.result});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse result data - handle multiple faces
    // Get all results if available (for displaying multiple faces info)
    final List<dynamic> allResults =
        widget.result['all_results'] ?? [widget.result];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hasil Prediksi',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black87),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Swipeable Images - Fixed height
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Page 1: Original Image
                _buildImagePage(
                  title: 'Original Image',
                  child: Image.file(widget.imageFile, fit: BoxFit.contain),
                ),

                // Page 2: Image with Bounding Box
                _buildImagePage(
                  title: 'Prediction Result',
                  child: _buildImageWithBoundingBoxes(allResults),
                ),
              ],
            ),
          ),

          // Page Indicator - moved below images
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                const SizedBox(width: 8),
                _buildPageIndicator(1),
              ],
            ),
          ),

          // Scrollable Prediction Info at Bottom
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Face Count Header
                          Row(
                            children: [
                              Icon(
                                Icons.face,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ditemukan ${allResults.length} wajah',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // API Analysis Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analisis Hasil API',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildAnalysisRow(
                                  'Status',
                                  widget.result['message'] ?? 'Success',
                                  Icons.check_circle,
                                ),
                                _buildAnalysisRow(
                                  'Jumlah Wajah',
                                  '${widget.result['face_count'] ?? allResults.length} wajah terdeteksi',
                                  Icons.face,
                                ),
                                _buildAnalysisRow(
                                  'Total Hasil',
                                  '${allResults.length} prediksi',
                                  Icons.list_alt,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section title for faces
                          const Text(
                            'Detail Setiap Wajah:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // List of all faces
                          ...allResults.asMap().entries.map((entry) {
                            final index = entry.key;
                            final result = entry.value;
                            final faceLabel = result['prediction'] ?? 'Unknown';
                            final faceConfidence = (result['confidence'] ?? 0.0)
                                .toDouble();

                            // FIX: NonFatigue = Green, Fatigue = Red
                            final isFatigue =
                                faceLabel.toLowerCase().contains('fatigue') &&
                                !faceLabel.toLowerCase().contains('non');
                            final faceColor = isFatigue
                                ? Colors.red
                                : Colors.green;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: faceColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: faceColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Face number badge
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: faceColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Face info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Label
                                        Row(
                                          children: [
                                            Text(
                                              'Wajah ${index + 1}:',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                faceLabel,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: faceColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Confidence percentage text
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.verified,
                                              size: 16,
                                              color: faceColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Confidence: ',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${(faceConfidence * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: faceColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Confidence bar
                                        Stack(
                                          children: [
                                            Container(
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: faceConfidence,
                                              child: Container(
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: faceColor,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 28,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${(faceConfidence * 100).toStringAsFixed(1)}%',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black45,
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePage({required String title, required Widget child}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
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
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWithBoundingBoxes(List<dynamic> allResults) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<img.Image?>(
          future: _getImageSize(widget.imageFile),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final original = snapshot.data!;
            final imgW = original.width.toDouble();
            final imgH = original.height.toDouble();

            // SOLUSI: Pakai FittedBox untuk scale gambar DAN bounding box bersama-sama
            // Koordinat bounding box langsung pakai nilai asli dari API (1:1 mapping)
            return FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: imgW,
                height: imgH,
                child: Stack(
                  children: [
                    // Gambar ukuran asli (FittedBox yang scale otomatis)
                    Image.file(
                      widget.imageFile,
                      width: imgW,
                      height: imgH,
                      fit: BoxFit.fill,
                    ),

                    // Bounding box digambar 1:1 terhadap koordinat API
                    ...allResults.asMap().entries.map((entry) {
                      return _drawBBox(entry.value, entry.key);
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Fungsi gambar bounding box - pakai koordinat asli (FittedBox yang handle scaling)
  Widget _drawBBox(dynamic result, int index) {
    final bbox = result['bounding_box'];
    if (bbox == null) return const SizedBox.shrink();

    final x1 = bbox[0].toDouble();
    final y1 = bbox[1].toDouble();
    final x2 = bbox[2].toDouble();
    final y2 = bbox[3].toDouble();

    final w = x2 - x1;
    final h = y2 - y1;

    final label = result['prediction'] ?? 'Unknown';
    final conf = (result['confidence'] ?? 0.0).toDouble() * 100;
    final isFatigue =
        label.toLowerCase().contains('fatigue') &&
        !label.toLowerCase().contains('non');

    final color = isFatigue ? Colors.red : Colors.green;

    return Positioned(
      left: x1,
      top: y1,
      width: w,
      height: h,
      child: Stack(
        children: [
          // Border bounding box
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
            ),
          ),

          // Label di atas
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              color: color,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '$label (${conf.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Badge nomor
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi baca ukuran gambar asli
  Future<img.Image?> _getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    return img.decodeImage(bytes);
  }
}
