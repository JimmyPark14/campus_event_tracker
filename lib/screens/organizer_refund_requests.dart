import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';
import 'package:image_picker/image_picker.dart';

class OrganizerRefundRequests extends StatefulWidget {
  final String eventId;

  const OrganizerRefundRequests({super.key, required this.eventId});

  @override
  State<OrganizerRefundRequests> createState() => _OrganizerRefundRequestsState();
}

class _OrganizerRefundRequestsState extends State<OrganizerRefundRequests> {
  final ImagePicker _picker = ImagePicker();

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = names.length > 2 ? 2 : names.length;
    for (int i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0];
      }
    }
    return initials.toUpperCase();
  }

  Future<void> _showRefundDialog(Map<String, dynamic> request, double amount) async {
    String uploadedRefundBase64 = '';
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Process Refund Request'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${request['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('ID: ${(request['userId'].hashCode.abs() % 100000000).toString().padLeft(8, '0')}'),
                    Text('Amount to Refund (75%): RM ${(amount * 0.75).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 12),
                    const Text('Refund Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request['refundReason'] ?? 'No reason provided', style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    const Text('Student Payment Receipt:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (request['receiptBase64'] != null && request['receiptBase64'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(request['receiptBase64']),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Text('No receipt found.'),
                    const SizedBox(height: 24),
                    const Text('Upload Refund Proof (Transfer Receipt):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setState(() {
                            uploadedRefundBase64 = base64Encode(bytes);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          border: Border.all(
                            color: uploadedRefundBase64.isEmpty 
                              ? Theme.of(context).colorScheme.outlineVariant 
                              : Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: uploadedRefundBase64.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary, size: 32),
                                const SizedBox(height: 8),
                                Text('Tap to upload refund receipt', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(base64Decode(uploadedRefundBase64), fit: BoxFit.cover),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploadedRefundBase64.isEmpty ? null : () async {
                    Navigator.pop(context);
                    await context.read<EventProvider>().processRefund(widget.eventId, request['userId'], uploadedRefundBase64);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund approved and student notified.')));
                    }
                  },
                  child: const Text('Approve & Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventProvider>().getEventById(widget.eventId);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Refund Requests')),
        body: const Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Refund Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<RegistrationProvider>().getPendingRefundsStream(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending refund requests.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final regDoc = docs[index];
              final data = regDoc.data() as Map<String, dynamic>;
              final userId = regDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final name = userData?['name'] ?? 'Unknown User';
                  
                  final request = {
                    ...data,
                    'userId': userId,
                    'name': name,
                    'initials': _getInitials(name),
                  };

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        child: Text(
                          request['initials'], 
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ID: ${(userId.hashCode.abs() % 100000000).toString().padLeft(8, '0')} • Paid: RM ${event.price.toStringAsFixed(2)} • Refund: RM ${(event.price * 0.75).toStringAsFixed(2)}'),
                      trailing: ElevatedButton(
                        onPressed: () => _showRefundDialog(request, event.price.toDouble()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        child: const Text('Process'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
