import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cloud_backup_service.dart';

class BeautifulBackupCard extends StatefulWidget {
  final CloudBackupMetadata backup;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final int index;

  const BeautifulBackupCard({
    super.key,
    required this.backup,
    this.onRestore,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<BeautifulBackupCard> createState() => _BeautifulBackupCardState();
}

class _BeautifulBackupCardState extends State<BeautifulBackupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeBackup = widget.backup.size > 50 * 1024 * 1024; // 50MB+ shows as large
    final isVeryLarge = widget.backup.size > 200 * 1024 * 1024; // 200MB+ shows special handling notice
    final formatFileSize = CloudBackupService().formatFileSize;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showBackupActions(context),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isVeryLarge 
                          ? Colors.purple.withValues(alpha: 0.2)
                          : isLargeBackup 
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isVeryLarge 
                                ? Colors.purple 
                                : isLargeBackup 
                                ? Colors.orange 
                                : Colors.blue)
                            .withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBackupIcon(isVeryLarge, isLargeBackup),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.backup.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created ${DateFormat('MMM dd, yyyy at HH:mm').format(widget.backup.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildSizeChip(formatFileSize(widget.backup.size), isVeryLarge, isLargeBackup),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.devices_rounded,
                            widget.backup.deviceInfo,
                            Colors.grey[600]!,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.apps_rounded,
                            'v${widget.backup.appVersion}',
                            Colors.grey[600]!,
                          ),
                          const Spacer(),
                          if (isVeryLarge)
                            _buildVeryLargeChip()
                          else if (isLargeBackup)
                            _buildLargeChip(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Restore',
                              Icons.restore_rounded,
                              Colors.blue, // All backups can be restored with streaming
                              widget.onRestore,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Delete',
                              Icons.delete_outline_rounded,
                              Colors.red,
                              widget.onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupIcon(bool isVeryLarge, bool isLargeBackup) {
    Color iconColor;
    Color backgroundColor;
    IconData icon;

    if (isVeryLarge) {
      iconColor = Colors.purple[600]!;
      backgroundColor = Colors.purple[50]!;
      icon = Icons.cloud_rounded; // Special icon for very large backups
    } else if (isLargeBackup) {
      iconColor = Colors.orange[600]!;
      backgroundColor = Colors.orange[50]!;
      icon = Icons.storage_rounded;
    } else {
      iconColor = Colors.blue[600]!;
      backgroundColor = Colors.blue[50]!;
      icon = Icons.backup_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildSizeChip(String size, bool isVeryLarge, bool isLargeBackup) {
    Color backgroundColor;
    Color textColor;

    if (isVeryLarge) {
      backgroundColor = Colors.purple[50]!;
      textColor = Colors.purple[700]!;
    } else if (isLargeBackup) {
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
    } else {
      backgroundColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        size,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeryLargeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_rounded, size: 14, color: Colors.purple[600]),
          const SizedBox(width: 4),
          Text(
            'Streaming',
            style: TextStyle(
              fontSize: 11,
              color: Colors.purple[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange[600]),
          const SizedBox(width: 4),
          Text(
            'Large',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
    final isDisabled = onPressed == null;
    
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? Colors.grey[400] : color,
          side: BorderSide(
            color: isDisabled ? Colors.grey[300]! : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showBackupActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
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
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildBackupIcon(
                    widget.backup.size > 200 * 1024 * 1024,
                    widget.backup.size > 50 * 1024 * 1024,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.backup.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created ${DateFormat('MMMM dd, yyyy at HH:mm').format(widget.backup.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () { // All sizes supported now
                                  Navigator.pop(context);
                                  widget.onRestore?.call();
                                },
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Restore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}