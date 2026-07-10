import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:typed_data';

class DynamicAvatar extends StatelessWidget {
  final String? name;
  final double radius;
  final double? fontSize;
  final String? avatarUrl;

  const DynamicAvatar({
    super.key,
    required this.name,
    this.radius = 64,
    this.fontSize,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipOval(
          child: avatarUrl!.startsWith('data:image') 
              ? Image.memory(
                  _decodeBase64Image(avatarUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
                )
              : CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildInitialsAvatar(),
                ),
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  // Helper method to decode base64
  Uint8List _decodeBase64Image(String dataUri) {
    final parts = dataUri.split(',');
    if (parts.length > 1) {
      return base64Decode(parts[1]);
    }
    return base64Decode(dataUri);
  }

  Widget _buildInitialsAvatar() {
    final String initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    
    // Generate a consistent color based on the name's hash code
    // Using abs() in case hash is negative
    final int hash = name?.hashCode.abs() ?? 0;
    final List<Color> colors = [
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.purple.shade400,
      Colors.deepPurple.shade400,
      Colors.indigo.shade400,
      Colors.blue.shade400,
      Colors.lightBlue.shade400,
      Colors.cyan.shade400,
      Colors.teal.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
    ];
    final Color backgroundColor = colors[hash % colors.length];

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize ?? (radius * 0.75),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
