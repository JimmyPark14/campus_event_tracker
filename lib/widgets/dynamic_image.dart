import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

ImageProvider getDynamicImageProvider(String url, {String fallbackName = 'Event'}) {
  if (url.startsWith('data:image')) {
    final parts = url.split(',');
    final base64Str = parts.length > 1 ? parts[1] : url;
    return MemoryImage(base64Decode(base64Str));
  } else if (url.isNotEmpty && !url.contains('ui-avatars.com')) {
    return CachedNetworkImageProvider(url);
  } else {
    return NetworkImage('https://ui-avatars.com/api/?name=$fallbackName&background=random');
  }
}

class DynamicImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String fallbackName;

  const DynamicImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackName = 'Event',
  });

  Uint8List _decodeBase64Image(String dataUri) {
    final parts = dataUri.split(',');
    if (parts.length > 1) {
      return base64Decode(parts[1]);
    }
    return base64Decode(dataUri);
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      return Image.memory(
        _decodeBase64Image(imageUrl),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else if (imageUrl.isNotEmpty && !imageUrl.contains('ui-avatars.com')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.network(
        'https://ui-avatars.com/api/?name=$fallbackName&background=random',
        fit: fit,
        width: width,
        height: height,
      );
    }
  }
}
