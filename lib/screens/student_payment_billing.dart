import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class StudentPaymentBilling extends StatefulWidget {
  const StudentPaymentBilling({super.key});

  @override
  State<StudentPaymentBilling> createState() => _StudentPaymentBillingState();
}

class _StudentPaymentBillingState extends State<StudentPaymentBilling> {
  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().firebaseUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('registrations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No billing history yet.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final eventId = data['eventId'] ?? '';
    final status = data['status'] ?? 'pending';
    final refundStatus = data['refundStatus'] ?? 'none';
    final timestamp = data['timestamp'] as Timestamp?;
    
    // Format date properly
    final dateStr = timestamp != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate()) 
        : 'Unknown Date';
    final paymentMethod = data['paymentMethod'] ?? 'Card';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
      builder: (context, snapshot) {
        String title = 'Loading event...';
        String amount = 'RM --';
        
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final eventData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          title = eventData['title'] ?? 'Unknown Event';
          
          var priceData = eventData['price'];
          if (priceData is num && priceData > 0) {
            amount = 'RM ${priceData.toInt()}';
          } else if (priceData is String && priceData.toLowerCase() != 'free' && priceData != '0' && priceData.isNotEmpty) {
            amount = 'RM $priceData';
          } else {
            amount = 'Free';
          }
        }
        
        // Don't show free events in billing history
        if (amount == 'Free' || amount == 'RM 0') {
          return const SizedBox.shrink();
        }

        // Determine if it's refunded
        final isRefunded = refundStatus == 'approved';
        final displayStatus = isRefunded ? 'refunded' : status;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              if (displayStatus != 'confirmed' && displayStatus != 'refunded') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt is only available for confirmed or refunded payments.'))
                );
                return;
              }
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptPreviewScreen(
                    title: title,
                    amount: amount,
                    dateStr: dateStr,
                    paymentMethod: paymentMethod,
                    status: displayStatus,
                    transactionId: doc.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr • $paymentMethod',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          decoration: isRefunded ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isRefunded ? Icons.assignment_return : (status == 'confirmed' ? Icons.check_circle : Icons.pending), 
                            size: 14, 
                            color: isRefunded ? Colors.purple.shade600 : (status == 'confirmed' ? Colors.green.shade600 : Colors.orange.shade600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isRefunded ? Colors.purple.shade600 : (status == 'confirmed' ? Colors.green.shade600 : Colors.orange.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReceiptPreviewScreen extends StatelessWidget {
  final String title;
  final String amount;
  final String dateStr;
  final String paymentMethod;
  final String status;
  final String transactionId;

  const ReceiptPreviewScreen({
    super.key,
    required this.title,
    required this.amount,
    required this.dateStr,
    required this.paymentMethod,
    required this.status,
    required this.transactionId,
  });

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    
    final isRefunded = status == 'refunded';
    final receiptType = isRefunded ? 'REFUND RECEIPT' : 'PAYMENT RECEIPT';

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Campus Event Tracker',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    receiptType,
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: isRefunded ? PdfColors.purple600 : PdfColors.grey600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 32),
                
                pw.Divider(),
                pw.SizedBox(height: 16),
                
                _buildRow('Transaction ID:', transactionId),
                pw.SizedBox(height: 8),
                _buildRow('Date:', dateStr),
                pw.SizedBox(height: 8),
                _buildRow('Event:', title),
                pw.SizedBox(height: 8),
                _buildRow('Payment Method:', paymentMethod),
                
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
                
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Amount', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(isRefunded ? '-$amount' : amount, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                
                pw.SizedBox(height: 48),
                
                pw.Center(
                  child: pw.Text(
                    isRefunded 
                        ? 'This transaction was refunded successfully. The original payment is now invalid.'
                        : 'Thank you for your payment! Present this receipt if required.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
