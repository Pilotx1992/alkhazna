import 'package:al_khazna/screens/backup_management_screen.dart';
import 'package:al_khazna/screens/cloud_backup_screen.dart';
import 'package:al_khazna/services/backup_service.dart';
import 'package:al_khazna/services/enhanced_backup_service.dart';
import 'package:al_khazna/widgets/backup_status_widget.dart';
import 'package:flutter/material.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  String _currentOperation = '';

  void _createBackup() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Starting backup...';
    });
    
    await _backupService.createBackup(
      context,
      onProgress: (status) {
        setState(() {
          _currentOperation = status;
        });
      },
    );
    
    setState(() {
      _isLoading = false;
      _currentOperation = '';
    });
  }

  void _createCloudBackup() async {
    final enhancedService = EnhancedBackupService();
    await enhancedService.createManualBackup(context);
  }

  void _restoreBackup() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Starting restore...';
    });
    
    await _backupService.restoreBackup(
      context,
      onProgress: (status) {
        setState(() {
          _currentOperation = status;
        });
      },
    );
    
    setState(() {
      _isLoading = false;
      _currentOperation = '';
    });
  }

  void _manageBackups() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackupManagementScreen()),
    );
  }

  void _openCloudBackups() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CloudBackupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const BackupSettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        _currentOperation,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cloud Backup Status
                        const BackupStatusWidget(showFullStatus: true),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: const Icon(Icons.backup, size: 64, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Backup & Restore',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Keep your financial data safe and secure',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.save, color: Color(0xFF2196F3), size: 32),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Local Backups',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _createBackup,
                                        icon: const Icon(Icons.add_box_rounded),
                                        label: const Text('Local'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF2196F3),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _createCloudBackup,
                                        icon: const Icon(Icons.cloud_upload),
                                        label: const Text('Cloud'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _restoreBackup,
                                  icon: const Icon(Icons.restore_page_rounded),
                                  label: const Text('Restore from File'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Color(0xFF2196F3),
                                    side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _manageBackups,
                                  icon: const Icon(Icons.folder_open_rounded),
                                  label: const Text('Manage Local Backups'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Color(0xFF2196F3),
                                    side: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.cloud, color: Colors.deepPurple, size: 32),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Cloud Backups',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openCloudBackups,
                                  icon: const Icon(Icons.cloud_upload_rounded),
                                  label: const Text('Cloud Backup & Restore'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}