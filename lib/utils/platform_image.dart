import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Displays an [XFile] image in a platform-safe way.
///
/// - **Web**: reads bytes via [XFile.readAsBytes] → [Image.memory]
/// - **Mobile**: uses the blob URL on the path → [Image.network] (image_picker
///   on web returns a blob:// URL, on mobile we use XFile.readAsBytes too,
///   because Image.file requires dart:io which won't compile on web targets)
///
/// Using [XFile.readAsBytes] for both platforms is the safest universal approach.
class XFileImage extends StatefulWidget {
  final XFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  const XFileImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<XFileImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      final bytes = await widget.file.readAsBytes();
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    if (_loading) {
      return SizedBox(
        width: w,
        height: h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error || _bytes == null) {
      return Container(
        width: w,
        height: h,
        color: const Color(0xFF1A1F33),
        child:
            const Icon(Icons.broken_image_outlined, color: Color(0xFF8899CC)),
      );
    }

    return Image.memory(
      _bytes!,
      width: w,
      height: h,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        color: const Color(0xFF1A1F33),
        child:
            const Icon(Icons.broken_image_outlined, color: Color(0xFF8899CC)),
      ),
    );
  }
}
