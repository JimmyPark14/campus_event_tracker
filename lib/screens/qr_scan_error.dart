import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../widgets/dynamic_image.dart';


class QrScanError extends StatelessWidget {
  final String? participantName;
  final String? participantId;
  final String? avatarUrl;

  const QrScanError({
    super.key,
    this.participantName,
    this.participantId,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background for camera view
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan QR Code',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated Camera View (Placeholder)
          Container(
            color: Theme.of(context).colorScheme.inverseSurface,
            child: Opacity(
              opacity: 0.5,
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? DynamicImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.person, size: 120, color: Colors.white54),
                    ),
            ),
          ),

          // Scanner Overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Align QR code within the frame',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 4.0,
                        color: Colors.black45,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Viewfinder Frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Corners
                      _buildCorner(context, top: -2, left: -2, width: 40, height: 40, isTop: true, isLeft: true),
                      _buildCorner(context, top: -2, right: -2, width: 40, height: 40, isTop: true, isLeft: false),
                      _buildCorner(context, bottom: -2, left: -2, width: 40, height: 40, isTop: false, isLeft: true),
                      _buildCorner(context, bottom: -2, right: -2, width: 40, height: 40, isTop: false, isLeft: false),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(context,
                      icon: Icons.flashlight_on,
                      label: 'Flash',
                      onPressed: () {
                        debugPrint('Feature not implemented');
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildControlButton(context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onPressed: () {
                        debugPrint('Feature not implemented');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Overlay (Backdrop + Dialog)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Error Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.priority_high, color: Theme.of(context).colorScheme.onError, size: 32),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title & Message
                      Text(
                        'Invalid QR Code',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This code is not recognized in our system or has already been checked in.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Actions
                      ElevatedButton.icon(
                        onPressed: () { context.pop(); },
                        icon: const Icon(Icons.refresh),
                        label: const Text('TRY AGAIN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          debugPrint('Feature not implemented');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(
                          'Enter Code Manually',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(BuildContext context, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double width,
    required double height,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 4) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 4) : BorderSide.none,
            left: isLeft ? BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 4) : BorderSide.none,
            right: !isLeft ? BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(24) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(24) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
