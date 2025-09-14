import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_sharing_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _previewData;
  String? _selectedFilePath;

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _previewData = null;
        _selectedFilePath = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _selectedFilePath = file.path;

        if (_selectedFilePath != null) {
          // Get preview of the data
          final preview = await DataSharingService.getImportPreview(_selectedFilePath!);
          setState(() {
            _previewData = preview;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData(ImportMode mode) async {
    if (_selectedFilePath == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Import the data file
      final data = await DataSharingService.importDataFile(_selectedFilePath!);

      // Process the imported data
      await DataSharingService.processImportedData(
        data: data,
        mode: mode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the import screen and return to home
        Navigator.of(context).pop(true); // Return true to indicate successful import
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<ImportMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'How would you like to import this data?\n\n'
            '• Replace: Remove all existing data and replace with imported data\n'
            '• Integrate: Merge imported data with existing data (no duplicates)'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImportMode.integrate),
              child: const Text('Integrate'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImportMode.replace),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _importData(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Import AlKhazna Data File',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select an AlKhazna data file (.alkhazna) to import income and expense data into your app.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pick File Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.file_present, size: 24),
                      label: const Text(
                        'Select Data File',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // File Preview
                  if (_previewData != null) ...[
                    const Text(
                      'File Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPreviewInfo('Export Type', _previewData!['type'] == 'month' ? 'Single Month' : 'All Data'),

                          if (_previewData!['type'] == 'month') ...[
                            _buildPreviewInfo('Month', '${_previewData!['month']} ${_previewData!['year']}'),
                          ] else ...[
                            _buildPreviewInfo('Months Count', '${_previewData!['monthsCount']} months'),
                          ],

                          _buildPreviewInfo('Income Entries', '${_previewData!['incomeCount']} entries'),
                          _buildPreviewInfo('Expense Entries', '${_previewData!['outcomeCount']} entries'),
                          _buildPreviewInfo('Export Date', DateTime.parse(_previewData!['exportDate']).toLocal().toString().split('.')[0]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Import Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showImportDialog,
                        icon: const Icon(Icons.download, size: 24),
                        label: const Text(
                          'Import Data',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Add bottom padding to prevent overflow
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}