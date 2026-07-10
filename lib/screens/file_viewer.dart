import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';

class FileViewerScreen extends StatefulWidget {
  final String format;
  final String filePath;

  const FileViewerScreen({super.key, required this.format, required this.filePath});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  List<List<dynamic>> _csvData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (widget.format == 'CSV' && widget.filePath.isNotEmpty) {
      try {
        final file = File(widget.filePath);
        final content = await file.readAsString();
        final List<List<dynamic>> rows = Csv().decode(content);
        setState(() {
          _csvData = rows;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CampusEventTracker_Export.${widget.format.toLowerCase()}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Previewing ${widget.format} Data',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: widget.format == 'PDF' ? _buildPdfPreview() : _buildSpreadsheetPreview(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (widget.filePath.isEmpty) return const Center(child: Text('No file found.'));
    final file = File(widget.filePath);
    return PdfPreview(
      build: (format) => file.readAsBytes(),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    );
  }

  Widget _buildSpreadsheetPreview(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_csvData.isEmpty) return const Center(child: Text('No data or file not found.'));

    final headers = _csvData.first;
    final rows = _csvData.sublist(1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
          columns: headers.map((h) => DataColumn(label: Text(h.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: rows.map((r) => DataRow(
            cells: r.map((c) => DataCell(Text(c.toString()))).toList(),
          )).toList(),
        ),
      ),
    );
  }
}
