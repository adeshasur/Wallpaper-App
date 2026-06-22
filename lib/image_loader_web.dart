// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformImage(String url, BoxFit fit) {
  // Use a clean sanitised view type name using the hash code of the URL
  final viewType = 'img_${url.hashCode}';

  // Register the view factory for the standard HTML <img> element
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final img = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
    return img;
  });

  return HtmlElementView(viewType: viewType);
}
