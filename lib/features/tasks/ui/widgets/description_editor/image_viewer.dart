import 'package:flutter/material.dart';

import 'storage_image.dart';

/// Full-screen, pinch/scroll-to-zoom image viewer.
Future<void> showImageViewer(BuildContext context, String path) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(path: path),
      ),
    );

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SizedBox.expand(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 6,
          child: Center(
            child: StorageImage(path: path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
