import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/registration_provider.dart';

class StudentPayment extends StatefulWidget {
  final String eventId;
  const StudentPayment({super.key, required this.eventId});

  @override
  State<StudentPayment> createState() => _StudentPaymentState();
}

class _StudentPaymentState extends State<StudentPayment> {
  String _selectedMethod = 'DuitNow QR';
  String _organizerQrBase64 = '';
  String _uploadedReceiptBase64 = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganizerQr();
  }

  Future<void> _fetchOrganizerQr() async {
    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId);
    if (event != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(event.organizerId).get();
      if (doc.exists && doc.data()!.containsKey('duitNowQrBase64')) {
        setState(() {
          _organizerQrBase64 = doc.data()!['duitNowQrBase64'];
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = result.files.single.extension?.toLowerCase();

      setState(() {
        _isLoading = true;
      });

      try {
        if (extension == 'pdf') {
          final document = await PdfDocument.openFile(path);
          final page = await document.getPage(1);
          final pageImage = await page.render(
            width: page.width * 2, 
            height: page.height * 2,
            format: PdfPageImageFormat.jpeg,
          );
          
          if (pageImage != null) {
            setState(() {
              _uploadedReceiptBase64 = base64Encode(pageImage.bytes);
            });
          }
          await page.close();
          await document.close();
        } else {
          final bytes = await File(path).readAsBytes();
          setState(() {
            _uploadedReceiptBase64 = base64Encode(bytes);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading receipt: \$e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    if (_uploadedReceiptBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your payment receipt')));
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Save receipt to Firebase
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.firebaseUser?.uid;
      if (userId != null) {
        if (mounted) {
          await context.read<RegistrationProvider>().submitPayment(
            widget.eventId, 
            userId, 
            _uploadedReceiptBase64
          );
        }
        
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.check_circle, size: 48, color: Theme.of(context).colorScheme.secondary),
            title: const Text('Payment Submitted'),
            content: const Text('Your payment receipt has been sent to the organizer. You will be fully registered once verified.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  context.go('/my-events'); // go back to my events
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().getEventById(widget.eventId);
    if (event == null || _isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        event.displayPrice,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        event.displayPrice,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Methods
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPaymentMethod(
              icon: Icons.qr_code_2,
              title: 'DuitNow QR',
              subtitle: 'Scan and upload receipt',
            ),

            const SizedBox(height: 16),
              const SizedBox(height: 24),
              Text(
                'Organizer DuitNow QR',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_organizerQrBase64.isNotEmpty)
                Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_organizerQrBase64)),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Organizer has not uploaded a QR code.'),
                  ),
                ),
                
              const SizedBox(height: 24),
              Text(
                'Upload Payment Receipt',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickReceipt,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    border: Border.all(
                      color: _uploadedReceiptBase64.isEmpty 
                        ? Theme.of(context).colorScheme.outlineVariant 
                        : Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _uploadedReceiptBase64.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary, size: 32),
                          const SizedBox(height: 8),
                          Text('Tap to upload receipt (JPG/PNG/PDF)', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(base64Decode(_uploadedReceiptBase64), fit: BoxFit.cover),
                      ),
                ),
              ),



            const SizedBox(height: 48),
            
            // Pay Button
            ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Pay ${event.displayPrice}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    bool isSelected = _selectedMethod == title;
    return Material(
      color: Colors.transparent,
      child: Container(
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
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = title;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

