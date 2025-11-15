import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';

class PhotosScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const PhotosScreen({super.key, required this.onNavigate});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final List<String> _photos = [
    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
    'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800',
    'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800',
    'https://images.unsplash.com/photo-1583504403615-fe7c48c5b9a6?w=800',
    'https://images.unsplash.com/photo-1566577134770-93d89dd44b68?w=800',
    'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=800',
    'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=800',
    'https://images.unsplash.com/photo-1540611025311-01df3cef54b5?w=800',
    'https://images.unsplash.com/photo-1583414775011-c14f6e4dfa48?w=800',
    'https://images.unsplash.com/photo-1555663165-3a8e93a9e727?w=800',
  ];

  void _openPhoto(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewScreen(
          imageUrl: _photos[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text(
                      'Thư viện ảnh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        // Show filter options
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Photos Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openPhoto(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 50),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha((255*0.3).toInt()),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentScreen: 'photos',
        onNavigate: widget.onNavigate,
      ),
    );
  }
}

// Full screen photo viewer with zoom and download
class PhotoViewScreen extends StatefulWidget {
  final String imageUrl;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tải ảnh...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with zoom
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              onInteractionUpdate: (details) {
                final scale = _transformationController.value.getMaxScaleOnAxis();
                setState(() {
                  _isZoomed = scale > 1.0;
                });
              },
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((255*0.7).toInt()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (_isZoomed)
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _handleDownload,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom hint
          if (!_isZoomed)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((255*0.7).toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Phóng to để tải ảnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
