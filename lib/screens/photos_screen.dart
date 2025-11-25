import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';
import 'camera_screen.dart';

class PhotosScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;
  final bool isPickerMode;

  const PhotosScreen({
    super.key,
    required this.onNavigate,
    this.isPickerMode = false,
  });

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<File> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() { _isLoading = true; });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${directory.path}/photos');
      if (await photosDir.exists()) {
        final files = await photosDir.list().toList();
        _photos = files.whereType<File>().toList();
      } else {
        _photos = [];
      }
    } catch (e) {
      print('Error loading photos: $e');
      _photos = [];
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.get('photos_library')),
        leading: widget.isPickerMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (!widget.isPickerMode)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
                if (result == true) {
                  _loadPhotos(); // Refresh photos after taking a new one
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Text(
                    appLocalizations.get('no_photos_message'),
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () {
                        if (widget.isPickerMode) {
                          Navigator.of(context).pop(photo);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoViewScreen(photo: photo),
                            ),
                          );
                        }
                      },
                      child: Image.file(photo, fit: BoxFit.cover),
                    );
                  },
                ),
      bottomNavigationBar: widget.isPickerMode
          ? null
          : BottomNavigationBarWidget(
              currentScreen: 'photos',
              onNavigate: widget.onNavigate,
            ),
    );
  }
}

class PhotoViewScreen extends StatelessWidget {
  final File photo;

  const PhotoViewScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                try {
                  await Gal.putImage(photo.path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.get('save_success'))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appLocalizations.get('save_general_error')}$e')),
                  );
                }
              },
            )
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(photo),
        heroAttributes: PhotoViewHeroAttributes(tag: photo.path),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}
