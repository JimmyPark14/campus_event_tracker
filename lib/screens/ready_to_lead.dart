import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

class ReadyToLead extends StatefulWidget {
  const ReadyToLead({super.key});

  @override
  State<ReadyToLead> createState() => _ReadyToLeadState();
}

class _ReadyToLeadState extends State<ReadyToLead> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const ConfettiBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(32),
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
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "You're ready to lead!",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Your organization portal is now active. You can now start by creating your first event.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/organizer/dashboard');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(double.infinity, 56),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Go to Dashboard',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              context.push('/organizer/create-event');
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(double.infinity, 56),
                              elevation: 1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create My First Event',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onSecondary),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiBackground extends StatefulWidget {
  const ConfettiBackground({super.key});

  @override
  State<ConfettiBackground> createState() => _ConfettiBackgroundState();
}

class _ConfettiBackgroundState extends State<ConfettiBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Base loop cycle duration
    )..repeat();

    _pieces = List.generate(30, (index) {
      return _ConfettiPiece(
        xPosition: _random.nextDouble(),
        durationMultiplier: (_random.nextDouble() * 3 + 2) / 10,
        delay: _random.nextDouble() * 2,
        colorIndex: _random.nextInt(5),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.secondaryContainer,
      Theme.of(context).colorScheme.primaryContainer,
      const Color(0xFF89D3D4), // secondary-fixed-dim
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Stack(
          children: _pieces.map((piece) {

            
            // The time since the animation started, factoring in loop boundaries natively
            // Since we're repeating, we actually just want a pure continuous time
            // So let's use the actual time
            final double totalElapsedTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

            final pieceDuration = piece.durationMultiplier * 10;
            final double activeTime = totalElapsedTime - piece.delay;

            // Let it delay before starting
            if (activeTime < 0) {
               return const SizedBox.shrink();
            }

            final progress = (activeTime % pieceDuration) / pieceDuration;

            final top = -20 + (screenHeight + 40) * progress;
            final left = (piece.xPosition * screenWidth) + (100 * progress);
            final rotation = progress * 2 * pi;
            final opacity = 1.0 - progress;

            return Positioned(
              top: top,
              left: left,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: 10,
                    height: 20,
                    color: colors[piece.colorIndex],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ConfettiPiece {
  final double xPosition;
  final double durationMultiplier;
  final double delay;
  final int colorIndex;

  _ConfettiPiece({
    required this.xPosition,
    required this.durationMultiplier,
    required this.delay,
    required this.colorIndex,
  });
}
