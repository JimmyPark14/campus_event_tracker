import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final String apkUrl;
  final String latestVersion;

  const UpdateDialog({
    super.key,
    required this.apkUrl,
    required this.latestVersion,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  bool _isDownloading = false;
  double _progress = 0.0;

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      await _updateService.downloadAndInstallUpdate(
        widget.apkUrl,
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
      
      // Close dialog after starting installation
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Version ${widget.latestVersion} is now available. Would you like to update?'),
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 10),
            Text('${(_progress * 100).toStringAsFixed(1)}% Downloaded'),
          ]
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
        ElevatedButton(
          onPressed: _isDownloading ? null : _startDownload,
          child: _isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update Now'),
        ),
      ],
    );
  }
}
