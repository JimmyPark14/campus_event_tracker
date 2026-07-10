import 'package:flutter/material.dart';
import '../widgets/dynamic_image.dart';

class CheckInConfirmation extends StatelessWidget {
  final String? participantName;
  final String? participantId;
  final String? avatarUrl;

  const CheckInConfirmation({
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
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Corners
                      _buildCorner(context, top: 0, left: 0, width: 32, height: 32, isTop: true, isLeft: true),
                      _buildCorner(context, top: 0, right: 0, width: 32, height: 32, isTop: true, isLeft: false),
                      _buildCorner(context, bottom: 0, left: 0, width: 32, height: 32, isTop: false, isLeft: true),
                      _buildCorner(context, bottom: 0, right: 0, width: 32, height: 32, isTop: false, isLeft: false),
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

          // Bottom Confirmation Banner
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participantName ?? 'Unknown Participant',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'ID: ${participantId ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Feature not implemented');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Check In',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(
    BuildContext context, {
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
            topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
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
