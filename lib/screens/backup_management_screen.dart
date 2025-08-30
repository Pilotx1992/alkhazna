
import 'dart:io';
import 'package:al_khazna/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  String _currentOperation = '';
  List<File> _backupFiles = [];
  String? _selectedDirectory;

  void _pickDirectory() async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      setState(() {
        _selectedDirectory = directoryPath;
        _loadBackupFiles(directoryPath);
      });
    }
  }

  void _loadBackupFiles(String directoryPath) {
    try {
      final directory = Directory(directoryPath);
      final files = directory
          .listSync()
          .where((item) => item is File && item.path.endsWith('.alk'))
          .map((item) => item as File)
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        _backupFiles = files;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading backup files: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _restoreBackup(File backupFile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text('Are you sure you want to restore from ${backupFile.path.split('\\').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _currentOperation = 'Starting restore...';
      });
      
      await _backupService.restoreBackup(
        context, // ignore: use_build_context_synchronously
        path: backupFile.path,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _currentOperation = status;
            });
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentOperation = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Backups'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _currentOperation,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _pickDirectory,
                    child: const Text('Select Backup Directory'),
                  ),
                ),
                if (_selectedDirectory != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Selected directory: $_selectedDirectory'),
                  ),
                Expanded(
                  child: _backupFiles.isEmpty
                      ? const Center(child: Text('No backup files found.'))
                      : ListView.builder(
                          itemCount: _backupFiles.length,
                          itemBuilder: (context, index) {
                            final file = _backupFiles[index];
                            final fileName = file.path.split('\\').last;
                            final fileSize = _formatFileSize(file.lengthSync());
                            final dateCreated = DateFormat('dd/MM/yyyy HH:mm').format(file.lastModifiedSync());
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: ListTile(
                                leading: const Icon(Icons.backup, color: Colors.blue),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Created: $dateCreated'),
                                    Text('Size: $fileSize'),
                                  ],
                                ),
                                trailing: const Icon(Icons.restore),
                                onTap: () => _restoreBackup(file),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
