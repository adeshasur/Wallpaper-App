import 'package:flutter/material.dart';
import 'image_loader_stub.dart'
    if (dart.library.html) 'image_loader_web.dart';

class SafeImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const SafeImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return buildPlatformImage(url, fit);
  }
}
