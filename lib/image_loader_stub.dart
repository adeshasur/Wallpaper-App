import 'package:flutter/material.dart';
import 'shimmer_placeholder.dart';

Widget buildPlatformImage(String url, BoxFit fit) {
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const ShimmerPlaceholder();
    },
  );
}
