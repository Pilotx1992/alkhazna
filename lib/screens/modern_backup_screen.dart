import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cloud_backup_service.dart';
import '../services/background_backup_service.dart';
import '../services/scheduled_backup_service.dart';
import '../widgets/modern_progress_widget.dart';

class ModernBackupScreen extends StatefulWidget {
  const ModernBackupScreen({super.key});

  @override
  State<ModernBackupScreen> createState() => _ModernBackupScreenState();
}

class _ModernBackupScreenState extends State<ModernBackupScreen>
    with TickerProviderStateMixin {
  final CloudBackupService _cloudBackupService = CloudBackupService();
  final BackgroundBackupService _backgroundService = BackgroundBackupService();
  final ScheduledBackupService _scheduledService = ScheduledBackupService();

  late AnimationController _mainAnimController;
  late AnimationController _fabAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabRotation;

  bool _isLoading = false;
  String _currentOperation = '';
  List<CloudBackupMetadata> _cloudBackups = [];
  double _operationProgress = 0.0;
  bool _operationComplete = false;
  String? _operationError;
  
  // Schedule info
  bool _isScheduleEnabled = false;
  String _scheduleFrequency = 'daily';
  DateTime? _nextBackup;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _mainAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainAnimController, curve: Curves.easeOutCubic),
    );

    _fabRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );

    _mainAnimController.forward();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCloudBackups(),
      _loadScheduleInfo(),
    ]);
  }

  Future<void> _loadCloudBackups() async {
    try {
      final backups = await _cloudBackupService.getCloudBackups(context);
      if (mounted) {
        setState(() {
          _cloudBackups = backups;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load backups: $e', isError: true);
      }
    }
  }

  Future<void> _loadScheduleInfo() async {
    try {
      await _scheduledService.initialize();
      final info = await _scheduledService.getScheduleInfo();
      
      if (mounted) {
        setState(() {
          _isScheduleEnabled = info['enabled'] ?? false;
          _scheduleFrequency = info['frequency'] ?? 'daily';
          _nextBackup = info['nextBackup'];
        });
      }
    } catch (e) {
      debugPrint('Failed to load schedule info: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _createBackup() async {
    if (_isLoading) return;
    
    _fabAnimController.forward().then((_) => _fabAnimController.reverse());
    
    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationComplete = false;
      _operationError = null;
      _currentOperation = 'Preparing backup...';
    });

    try {
      await _backgroundService.createBackgroundBackup(
        (status) {
          if (mounted) {
            setState(() {
              _currentOperation = status;
              final match = RegExp(r'(\d+)%').firstMatch(status);
              if (match != null) {
                _operationProgress = double.parse(match.group(1)!) / 100;
              }
            });
          }
        },
        (success, error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _operationComplete = success;
              _operationError = error;
              _operationProgress = success ? 1.0 : 0.0;
            });
            
            if (success) {
              _showSnackBar('Backup created successfully!');
              _loadCloudBackups();
            } else {
              _showSnackBar(error ?? 'Backup failed', isError: true);
            }
          }
        },
        context: context,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _operationError = e.toString();
        });
        _showSnackBar('Backup failed: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
          ? ModernProgressWidget(
              progress: _operationProgress,
              status: _currentOperation,
              isComplete: _operationComplete,
              error: _operationError,
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildScheduleCard(),
                      const SizedBox(height: 24),
                      _buildBackupsList(),
                    ]),
                  ),
                ),
              ],
            ),
      floatingActionButton: _isLoading ? null : _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: const Text(
              'Data Backups',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[50]!,
                Colors.white,
              ],
            ),
          ),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickStats() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Data',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_cloudBackups.length} Backup${_cloudBackups.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isScheduleEnabled 
                            ? 'Auto-backup $_scheduleFrequency'
                            : 'Manual backup only',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value + 20),
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isScheduleEnabled ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: _isScheduleEnabled ? Colors.green[600] : Colors.grey[500],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Automatic Backups',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isScheduleEnabled ? 'Active' : 'Disabled',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isScheduleEnabled ? Colors.green[600] : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isScheduleEnabled,
                      onChanged: (value) async {
                        try {
                          if (value) {
                            await _scheduledService.enableScheduledBackups(_scheduleFrequency);
                            _showSnackBar('Automatic backups enabled');
                          } else {
                            await _scheduledService.disableScheduledBackups();
                            _showSnackBar('Automatic backups disabled');
                          }
                          _loadScheduleInfo();
                        } catch (e) {
                          _showSnackBar('Failed to update schedule: $e', isError: true);
                        }
                      },
                    ),
                  ],
                ),
                if (_isScheduleEnabled && _nextBackup != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, 
                             color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Next backup: ${_formatDateTime(_nextBackup!)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value + 40),
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: Colors.purple[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Recent Backups',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_cloudBackups.isNotEmpty)
                        Text(
                          '${_cloudBackups.length}',
                          style: TextStyle(
                            color: Colors.purple[600],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_cloudBackups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No backups found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first backup to keep your data safe',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...(_cloudBackups.take(5).map((backup) => _buildBackupItem(backup))),
                if (_cloudBackups.length > 5)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to full backup list
                        },
                        child: Text(
                          'View all ${_cloudBackups.length} backups',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupItem(CloudBackupMetadata backup) {
    final isLarge = backup.size > 15 * 1024 * 1024;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            print('Backup tapped: ${backup.name}');
            _showBackupActions(backup);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLarge ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.backup_rounded,
                    color: isLarge ? Colors.orange[600] : Colors.green[600],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backup.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(backup.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _cloudBackupService.formatFileSize(backup.size),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLarge ? Colors.orange[600] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabRotation,
      builder: (context, child) => Transform.rotate(
        angle: _fabRotation.value * 0.1,
        child: FloatingActionButton.extended(
          onPressed: _createBackup,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 8,
          label: const Text(
            'Create Backup',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.backup_rounded),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM dd at HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'soon';
    }
  }

  void _showBackupActions(CloudBackupMetadata backup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              backup.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created ${DateFormat('MMM dd, yyyy at HH:mm').format(backup.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Restore',
                    Icons.restore_rounded,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      _restoreBackup(backup);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'Delete',
                    Icons.delete_rounded,
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      _deleteBackup(backup);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _restoreBackup(CloudBackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      title: 'Restore Backup',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restore_rounded,
            size: 48,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Restore from "${backup.name}"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Created: ${DateFormat('MMM dd, yyyy at HH:mm').format(backup.createdAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            'Size: ${_cloudBackupService.formatFileSize(backup.size)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will replace all your current data with the backup data.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      confirmText: 'Restore',
      confirmColor: Colors.orange[600]!,
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _operationProgress = 0.0;
        _operationComplete = false;
        _operationError = null;
        _currentOperation = 'Starting restore...';
      });

      try {
        await _backgroundService.restoreBackgroundBackup(
          backup,
          (status) {
            if (mounted) {
              setState(() {
                _currentOperation = status;
                final match = RegExp(r'(\d+)%').firstMatch(status);
                if (match != null) {
                  _operationProgress = double.parse(match.group(1)!) / 100;
                }
              });
            }
          },
          (success, error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _operationComplete = success;
                _operationError = error;
                _operationProgress = success ? 1.0 : 0.0;
              });
              
              if (success) {
                _showSnackBar('Backup restored successfully!');
                _showRestartDialog();
              } else {
                _showSnackBar(error ?? 'Restore failed', isError: true);
              }
            }
          },
          context: context,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _operationError = e.toString();
          });
          _showSnackBar('Restore failed: $e', isError: true);
        }
      }
    }
  }

  Future<void> _deleteBackup(CloudBackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Backup',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_forever_rounded,
            size: 48,
            color: Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Delete "${backup.name}"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This backup will be permanently deleted from the cloud.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      confirmText: 'Delete',
      confirmColor: Colors.red[600]!,
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _operationProgress = 0.0;
        _operationComplete = false;
        _operationError = null;
        _currentOperation = 'Deleting backup...';
      });

      try {
        await _backgroundService.deleteBackgroundBackup(
          backup,
          (status) {
            if (mounted) {
              setState(() {
                _currentOperation = status;
              });
            }
          },
          (success, error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _operationComplete = success;
                _operationError = error;
                _operationProgress = success ? 1.0 : 0.0;
              });
              
              if (success) {
                _showSnackBar('Backup deleted successfully!');
                _loadCloudBackups(); // Refresh the list
              } else {
                _showSnackBar(error ?? 'Delete failed', isError: true);
              }
            }
          },
          context: context,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _operationError = e.toString();
          });
          _showSnackBar('Delete failed: $e', isError: true);
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required Widget content,
    required String confirmText,
    required Color confirmColor,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Restore Complete!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your data has been restored successfully. Please restart the app for changes to take effect.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}