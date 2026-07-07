import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoCaptureField extends StatefulWidget {
  const PhotoCaptureField({
    required this.photo,
    required this.onPhotoCaptured,
    super.key,
  });

  final XFile? photo;
  final ValueChanged<XFile> onPhotoCaptured;

  @override
  State<PhotoCaptureField> createState() => _PhotoCaptureFieldState();
}

class _PhotoCaptureFieldState extends State<PhotoCaptureField> {
  final _picker = ImagePicker();
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    try {
      if (!kIsWeb) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permita o uso da camera.')),
          );
          return;
        }
      }

      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (photo != null) {
        widget.onPhotoCaptured(photo);
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Foto do local',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: photo == null
                    ? Container(
                        color: Colors.black.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_a_photo_outlined, size: 42),
                      )
                    : _PhotoPreview(photo: photo),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _capturing ? null : _capture,
              icon: _capturing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(photo == null ? 'Capturar foto' : 'Refazer foto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatefulWidget {
  const _PhotoPreview({required this.photo});

  final XFile photo;

  @override
  State<_PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<_PhotoPreview> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path) {
      _load();
    }
  }

  Future<void> _load() async {
    final bytes = await widget.photo.readAsBytes();
    if (mounted) {
      setState(() => _bytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Image.memory(bytes, fit: BoxFit.cover);
  }
}
