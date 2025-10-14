import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

class ExportButton extends StatefulWidget {
  final String month;
  final int year;

  const ExportButton({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  final _storageService = StorageService();
  bool _isExporting = false;

  Future<void> _exportToPdf() async {
    setState(() => _isExporting = true);

    try {
      final incomeEntries = await _storageService.getIncomeEntries(
        widget.month,
        widget.year,
      );
      final outcomeEntries = await _storageService.getOutcomeEntries(
        widget.month,
        widget.year,
      );

      await PdfService.generateAndPrintReport(
        month: widget.month,
        year: widget.year,
        incomeEntries: incomeEntries,
        outcomeEntries: outcomeEntries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while exporting the report'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : _exportToPdf,
      icon: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.picture_as_pdf, color: Colors.red),
      label: Text(_isExporting ? 'جاري التصدير...' : 'تصدير PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
    );
  }
}
