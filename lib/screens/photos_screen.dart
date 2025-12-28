import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:async/async.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../l10n/app_localizations.dart';
import 'camera_screen.dart';

class PhotosScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic> data}) onNavigate;
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
  Map<String, List<String>> _albums = {}; // albumName: [photoPaths]
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  bool _isSelectionMode = false;
  final Set<File> _selectedPhotos = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/albums.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        setState(() {
          _albums =
              data.map((key, value) => MapEntry(key, List<String>.from(value)));
        });
      }
    } catch (e) {
      print('Error loading albums: $e');
    }
  }

  Future<void> _saveAlbums() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/albums.json');
      await file.writeAsString(json.encode(_albums));
    } catch (e) {
      print('Error saving albums: $e');
    }
  }

  void _createNewAlbum(String name) {
    if (name.isEmpty) return;
    setState(() {
      _albums[name] = _selectedPhotos.map((f) => f.path).toList();
      _isSelectionMode = false;
      _selectedPhotos.clear();
    });
    _saveAlbums();
  }

  void _deleteAlbum(String name) {
    setState(() {
      _albums.remove(name);
    });
    _saveAlbums();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(File photo) async {
    try {
      await photo.delete();
      _loadPhotos(); // Refresh the list
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  Future<void> _pickAndSaveImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${directory.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(image.path).copy('${photosDir.path}/$fileName');
      _loadPhotos(); // Refresh the list
    } catch (e) {
      print('Error saving image: $e');
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
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigate('settings'),
              ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _showCreateAlbumDialog(),
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedPhotos.clear();
                });
              },
            ),
          if (!_isSelectionMode && !widget.isPickerMode)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: _pickAndSaveImage,
              tooltip: 'Thêm từ thư viện',
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          CameraScreen(onNavigate: widget.onNavigate)),
                );
                if (result == true) {
                  _loadPhotos(); // Refresh photos after taking a new one
                }
              },
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: appLocalizations.get('library_tab')),
                Tab(text: appLocalizations.get('albums_tab')),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLibraryTab(appLocalizations),
                  _buildAlbumsTab(appLocalizations),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isPickerMode
          ? null
          : BottomNavigationBarWidget(
              currentScreen: 'photos',
              onNavigate: widget.onNavigate,
            ),
    );
  }

  Widget _buildLibraryTab(AppLocalizations appLocalizations) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_photos.isEmpty) {
      return Center(
          child: Text(appLocalizations.get('no_photos_message'),
              textAlign: TextAlign.center));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final isSelected = _selectedPhotos.contains(photo);

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedPhotos.remove(photo);
                } else {
                  _selectedPhotos.add(photo);
                }
              });
            } else if (widget.isPickerMode) {
              Navigator.of(context).pop(photo);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoViewScreen(
                      photo: photo,
                      onDelete: _deletePhoto,
                      onNavigate: widget.onNavigate),
                ),
              );
            }
          },
          onLongPress: () {
            if (!widget.isPickerMode && !_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedPhotos.add(photo);
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(photo, fit: BoxFit.cover),
              if (_isSelectionMode)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.white,
                  ),
                ),
              if (!_isSelectionMode && !widget.isPickerMode)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _showAddToAlbumDialog(photo),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add_to_photos,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToAlbumDialog(File photo) {
    final appLocalizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(appLocalizations.get('create_album')),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAlbumDialogForSinglePhoto(photo);
                },
              ),
              const Divider(),
              if (_albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(appLocalizations.get('album_empty')),
                )
              else
                ..._albums.keys.map((albumName) => ListTile(
                      leading: const Icon(Icons.photo_album),
                      title: Text(albumName),
                      onTap: () {
                        setState(() {
                          if (!_albums[albumName]!.contains(photo.path)) {
                            _albums[albumName]!.add(photo.path);
                            _saveAlbums();
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to $albumName')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    appLocalizations.get('already_in_album'))));
                          }
                        });
                        Navigator.pop(context);
                      },
                    )),
            ],
          ),
        );
      },
    );
  }

  void _showCreateAlbumDialogForSinglePhoto(File photo) {
    final appLocalizations = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('create_album')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: appLocalizations.get('album_name_hint')),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.get('no_label'))),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _albums[name] = [photo.path];
                  _saveAlbums();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(appLocalizations.get('album_created_success'))));
              }
            },
            child: Text(appLocalizations.get('yes_label')),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsTab(AppLocalizations appLocalizations) {
    if (_albums.isEmpty) {
      return Center(
          child: Text(appLocalizations.get('album_empty'),
              textAlign: TextAlign.center));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final albumName = _albums.keys.elementAt(index);
        final photoPaths = _albums[albumName]!;
        final coverPhotoPath = photoPaths.isNotEmpty ? photoPaths.first : null;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumDetailScreen(
                  albumName: albumName,
                  photoPaths: photoPaths,
                  onNavigate: widget.onNavigate,
                  onUpdate: (updatedPaths) {
                    setState(() {
                      if (updatedPaths.isEmpty) {
                        _albums.remove(albumName);
                      } else {
                        _albums[albumName] = updatedPaths;
                      }
                    });
                    _saveAlbums();
                  },
                ),
              ),
            );
          },
          onLongPress: () {
            _showDeleteAlbumDialog(albumName, appLocalizations);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverPhotoPath != null
                      ? Image.file(File(coverPhotoPath),
                          fit: BoxFit.cover, width: double.infinity)
                      : const Center(
                          child: Icon(Icons.photo_library,
                              size: 40, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 4),
              Text(albumName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${photoPaths.length} items',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  void _showCreateAlbumDialog() {
    final appLocalizations = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.get('create_album')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: appLocalizations.get('album_name_hint')),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.get('no_label'))),
          TextButton(
            onPressed: () {
              _createNewAlbum(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(appLocalizations.get('album_created_success'))));
            },
            child: Text(appLocalizations.get('yes_label')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAlbumDialog(
      String albumName, AppLocalizations appLocalizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text(appLocalizations.get('delete_album_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.get('no_label'))),
          TextButton(
            onPressed: () {
              _deleteAlbum(albumName);
              Navigator.pop(context);
            },
            child: Text(appLocalizations.get('yes_label'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final List<String> photoPaths;
  final Function(String, {Map<String, dynamic> data}) onNavigate;
  final Function(List<String>) onUpdate;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.photoPaths,
    required this.onNavigate,
    required this.onUpdate,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late List<String> _currentPaths;

  @override
  void initState() {
    super.initState();
    _currentPaths = List.from(widget.photoPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () async {
              final File? pickedPhoto = await Navigator.push<File>(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotosScreen(
                    onNavigate: widget.onNavigate,
                    isPickerMode: true,
                  ),
                ),
              );

              if (pickedPhoto != null) {
                if (!_currentPaths.contains(pickedPhoto.path)) {
                  setState(() {
                    _currentPaths.add(pickedPhoto.path);
                  });
                  widget.onUpdate(_currentPaths);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo already in album')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _currentPaths.isEmpty
          ? const Center(child: Text('Album is empty'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _currentPaths.length,
              itemBuilder: (context, index) {
                final path = _currentPaths[index];
                final file = File(path);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoViewScreen(
                          photo: file,
                          onDelete: (f) async {
                            setState(() {
                              _currentPaths.remove(f.path);
                            });
                            widget.onUpdate(_currentPaths);
                          },
                          onNavigate: widget.onNavigate,
                        ),
                      ),
                    );
                  },
                  child: Image.file(file, fit: BoxFit.cover),
                );
              },
            ),
    );
  }
}

class PhotoViewScreen extends StatefulWidget {
  final File photo;
  final Future<void> Function(File) onDelete;
  final Function(String, {Map<String, dynamic> data}) onNavigate;

  const PhotoViewScreen(
      {super.key,
      required this.photo,
      required this.onDelete,
      required this.onNavigate});

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  bool _isProcessing = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _updateLandmark() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lỗi xác thực. Vui lòng đăng nhập lại.')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    try {
      var stream =
          http.ByteStream(DelegatingStream.typed(widget.photo.openRead()));
      var length = await widget.photo.length();

      var uri = Uri.parse(ApiConfig.landmarkDetectUpload);

      var request = http.MultipartRequest("POST", uri);
      var multipartFile = http.MultipartFile('file', stream, length,
          filename: p.basename(widget.photo.path),
          contentType: MediaType('image', 'jpeg'));

      request.files.add(multipartFile);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      var response = await request.send();

      if (!mounted) return;

      final responseBody = await response.stream.bytesToString();
      final result = jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          result['success'] == true &&
          result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;

        final name = data['Tên'] ?? 'N/A';
        final engName =
            data['Tên tiếng Anh'] != null ? ' (${data['Tên tiếng Anh']})' : '';
        final intro = data['Giới thiệu'] ?? 'Không có thông tin.';
        final similarity = (data['Điểm similarity'] as num?)?.toDouble() ?? 0.0;
        final highlights = data['Điểm đặc sắc'] as List<dynamic>? ?? [];
        final funFacts = data['Sự thật thú vị'] as List<dynamic>? ?? [];
        final story = data['Câu chuyện'] ?? '';
        final wikiUrl = data['Wikipedia'] ?? '';

        final highlightsString = highlights.map((e) => '- $e').join('\n');
        final funFactsString = funFacts.map((e) => '- $e').join('\n');

        final String resultString = '''
### $name$engName

**Độ tương đồng:** ${(similarity * 100).toStringAsFixed(1)}%

---

**Giới thiệu:**
$intro

**Điểm đặc sắc:**
$highlightsString

**Sự thật thú vị:**
$funFactsString

**Câu chuyện:**
>$story

**Tìm hiểu thêm:**
[$wikiUrl]($wikiUrl)
''';

        widget.onNavigate(
          'aiLandmarkResult',
          data: {'markdownContent': resultString, 'from': 'photos'},
        );
      } else {
        final String errorMessage = result['detail'] ??
            'Không nhận diện được địa danh từ ảnh. (${response.statusCode})';
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome), // AI Icon
            onPressed: _updateLandmark,
            tooltip: 'Cập nhật Landmark',
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                try {
                  await Gal.putImage(widget.photo.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(appLocalizations.get('save_success'))),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${appLocalizations.get('save_general_error')}$e')),
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: const Text('Bạn có chắc chắn muốn xóa ảnh này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                await widget.onDelete(widget.photo);
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(widget.photo),
            heroAttributes: PhotoViewHeroAttributes(tag: widget.photo.path),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("AI đang nhận diện...",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
