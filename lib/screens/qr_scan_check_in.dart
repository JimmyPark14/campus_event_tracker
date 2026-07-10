import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/event_provider.dart';
import '../utils/audio_generator.dart';
import '../theme.dart';

enum QrScanState { scanning, success, error }

class QrScanCheckIn extends StatefulWidget {
  const QrScanCheckIn({super.key});

  @override
  State<QrScanCheckIn> createState() => _QrScanCheckInState();
}

class _QrScanCheckInState extends State<QrScanCheckIn>
    with SingleTickerProviderStateMixin {
  bool _isFlashOn = false;
  bool _isKioskMode = false;
  late AnimationController _animationController;
  QrScanState _scanState = QrScanState.scanning;
  String _errorMsg = 'Invalid ticket.';
  String _lastScannedId = '';
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(bool success) async {
    try {
      if (success) {
        await _audioPlayer.play(BytesSource(AudioGenerator.generateSuccessSound()));
      } else {
        await _audioPlayer.play(BytesSource(AudioGenerator.generateErrorSound()));
      }
    } catch (e) {
      debugPrint('Audio play failed: $e');
    }
  }

  void _startScanning() {
    setState(() {
      _scanState = QrScanState.scanning;
    });
    _scannerController.start();
  }

  void _handleBarcode(String value) async {
    if (_scanState != QrScanState.scanning) return;

    _scannerController.stop();

    final parts = value.split('|');
    if (parts.length != 2) {
      _playSound(false);
      setState(() {
        _scanState = QrScanState.error;
        _errorMsg = 'Invalid QR format. Please use the official app.';
      });
      return;
    }

    final eventId = parts[0];
    final studentId = parts[1];

    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(eventId);

    if (event == null) {
      _playSound(false);
      setState(() {
        _scanState = QrScanState.error;
        _errorMsg = 'Event not found.';
      });
      return;
    }

    if (!event.registeredUserIds.contains(studentId)) {
      _playSound(false);
      setState(() {
        _scanState = QrScanState.error;
        _errorMsg = 'Ticket not found or has been refunded.';
      });
      return;
    }

    if (event.attendedUserIds.contains(studentId)) {
      _playSound(false);
      setState(() {
        _scanState = QrScanState.error;
        _errorMsg = 'Ticket has already been used.';
      });
      return;
    }

    _playSound(true);
    setState(() {
      _scanState = QrScanState.success;
      _lastScannedId = studentId;
    });

    try {
      await eventProvider.checkInUser(eventId, studentId);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        if (_isKioskMode) {
          _startScanning();
        } else {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      _playSound(false);
      setState(() {
        _scanState = QrScanState.error;
        _errorMsg = 'Failed to check in. Please check network.';
      });
      if (_isKioskMode) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) _startScanning();
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final BarcodeCapture? capture = await _scannerController.analyzeImage(
        image.path,
      );
      if (capture == null && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in the selected image.'),
          ),
        );
      } else if (capture != null && capture.barcodes.isNotEmpty) {
        if (capture.barcodes.first.rawValue != null) {
          _handleBarcode(capture.barcodes.first.rawValue!);
        }
      }
    }
  }

  void _showManualEntryDialog() {
    final TextEditingController matrixController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Manual Entry',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: matrixController,
            decoration: InputDecoration(
              labelText: 'Matrix No.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              Navigator.pop(context);
              if (value.isNotEmpty) {
                _startScanning();
                _handleBarcode(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (matrixController.text.isNotEmpty) {
                  _startScanning();
                  _handleBarcode(matrixController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    ).then((_) {
      matrixController.dispose();
    });
  }



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
        actions: [
          Row(
            children: [
              Text(
                'Kiosk Mode',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
              Switch(
                value: _isKioskMode,
                onChanged: (val) {
                  setState(() => _isKioskMode = val);
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Feed
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  _handleBarcode(barcode.rawValue!);
                }
              }
            },
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  'Error starting camera: ${error.errorCode}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          // Scanner Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 120.0,
              ), // Offset for bottom banners
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
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
                  ),
                  const SizedBox(height: 32),

                  // Viewfinder Frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // Simulated Scanning Line removed by user request
                        // Corners
                        _buildCorner(
                          top: -2,
                          left: -2,
                          width: 40,
                          height: 40,
                          isTop: true,
                          isLeft: true,
                        ),
                        _buildCorner(
                          top: -2,
                          right: -2,
                          width: 40,
                          height: 40,
                          isTop: true,
                          isLeft: false,
                        ),
                        _buildCorner(
                          bottom: -2,
                          left: -2,
                          width: 40,
                          height: 40,
                          isTop: false,
                          isLeft: true,
                        ),
                        _buildCorner(
                          bottom: -2,
                          right: -2,
                          width: 40,
                          height: 40,
                          isTop: false,
                          isLeft: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isFlashOn
                            ? Icons.flashlight_on
                            : Icons.flashlight_off,
                        label: 'Flash',
                        onPressed: () {
                          _scannerController.toggleTorch();
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                        isActive: _isFlashOn,
                      ),
                      const SizedBox(width: 24),
                      _buildControlButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _pickImageFromGallery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Status Banner
          _buildBottomBanner(),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    switch (_scanState) {
      case QrScanState.scanning:
        return Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Scan QR Code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Ready to scan',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Balance for centering
              ],
            ),
          ),
        );

      case QrScanState.success:
        return Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ahmad Faris',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'SUCCESS',
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontSize: 10,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $_lastScannedId',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.verified,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Continue Scanning'),
                ),
              ],
            ),
          ),
        );

      case QrScanState.error:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 48,
            ),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
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
                    child: Icon(
                      Icons.priority_high,
                      color: Theme.of(context).colorScheme.onError,
                      size: 32,
                    ),
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
                  _errorMsg,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Actions
                ElevatedButton.icon(
                  onPressed: _startScanning,
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
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _showManualEntryDialog,
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
        );
    }
  }

  Widget _buildCorner({
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
            top: isTop
                ? BorderSide(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    width: 4,
                  )
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(24) : Radius.zero,
            topRight: isTop && !isLeft
                ? const Radius.circular(24)
                : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(24)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(24)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
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
