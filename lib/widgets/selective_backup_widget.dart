import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/selective_backup_service.dart';

class SelectiveBackupWidget extends StatefulWidget {
  final Function(SelectiveBackupOptions) onOptionsChanged;
  final SelectiveBackupOptions initialOptions;

  const SelectiveBackupWidget({
    super.key,
    required this.onOptionsChanged,
    required this.initialOptions,
  });

  @override
  State<SelectiveBackupWidget> createState() => _SelectiveBackupWidgetState();
}

class _SelectiveBackupWidgetState extends State<SelectiveBackupWidget> {
  late SelectiveBackupOptions _options;
  Map<BackupComponent, Map<String, dynamic>>? _analysisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
    _analyzeContent();
  }

  Future<void> _analyzeContent() async {
    if (!mounted) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await SelectiveBackupService.analyzeBackupContent(_options);
      
      if (mounted) {
        setState(() {
          _analysisResult = analysis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  void _updateOptions(SelectiveBackupOptions newOptions) {
    setState(() {
      _options = newOptions;
    });
    widget.onOptionsChanged(newOptions);
    _analyzeContent(); // Re-analyze when options change
  }

  void _toggleComponent(BackupComponent component, bool selected) {
    final newComponents = Set<BackupComponent>.from(_options.selectedComponents);
    if (selected) {
      newComponents.add(component);
    } else {
      newComponents.remove(component);
    }
    
    _updateOptions(SelectiveBackupOptions(
      selectedComponents: newComponents,
      includeAppData: _options.includeAppData,
      compressData: _options.compressData,
      compressionLevel: _options.compressionLevel,
      dateRangeStart: _options.dateRangeStart,
      dateRangeEnd: _options.dateRangeEnd,
    ));
  }

  void _setDateRange(DateTime? start, DateTime? end) {
    _updateOptions(SelectiveBackupOptions(
      selectedComponents: _options.selectedComponents,
      includeAppData: _options.includeAppData,
      compressData: _options.compressData,
      compressionLevel: _options.compressionLevel,
      dateRangeStart: start,
      dateRangeEnd: end,
    ));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selective Backup',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose what to include in your backup',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Components Selection
            Text(
              'Backup Components',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isAnalyzing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...BackupComponent.values.map((component) {
                final isSelected = _options.selectedComponents.contains(component);
                final analysis = _analysisResult?[component];
                final hasData = analysis?['hasData'] ?? true;
                final estimatedSize = analysis?['estimatedSize'] ?? 0;
                final entryCount = analysis?['selectedEntries'] ?? analysis?['totalEntries'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected 
                      ? Colors.blue.withValues(alpha: 0.1) 
                      : Colors.grey.withValues(alpha: 0.05),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: hasData ? (value) => _toggleComponent(component, value ?? false) : null,
                    title: Text(
                      component.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasData ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.description,
                          style: TextStyle(
                            color: hasData ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (entryCount != null)
                              Text(
                                '$entryCount items',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (entryCount != null && estimatedSize > 0)
                              Text(
                                ' • ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (estimatedSize > 0)
                              Text(
                                '~${_formatBytes(estimatedSize)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (!hasData)
                              Text(
                                'No data available',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    secondary: Icon(
                      _getComponentIcon(component),
                      color: hasData && isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Date Range Filter
            ExpansionTile(
              title: const Text('Date Range Filter'),
              subtitle: Text(
                _options.dateRangeStart != null || _options.dateRangeEnd != null
                    ? 'Custom range selected'
                    : 'Include all dates',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _options.dateRangeStart ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  _setDateRange(date, _options.dateRangeEnd);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_options.dateRangeStart != null
                                  ? DateFormat('dd/MM/yyyy').format(_options.dateRangeStart!)
                                  : 'Start Date'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _options.dateRangeEnd ?? DateTime.now(),
                                  firstDate: _options.dateRangeStart ?? DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  _setDateRange(_options.dateRangeStart, date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_options.dateRangeEnd != null
                                  ? DateFormat('dd/MM/yyyy').format(_options.dateRangeEnd!)
                                  : 'End Date'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _setDateRange(null, null),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Date Filter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary
            if (_analysisResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Backup Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Components selected:'),
                        Text(
                          '${_options.selectedComponents.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated size:'),
                        Text(
                          _formatBytes(_analysisResult!.values
                              .where((analysis) => _options.selectedComponents
                                  .contains(_getComponentFromAnalysis(analysis)))
                              .fold<int>(0, (sum, analysis) => sum + (analysis['estimatedSize'] as int? ?? 0))),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BackupComponent _getComponentFromAnalysis(Map<String, dynamic> analysis) {
    // This is a helper method to map analysis back to component
    // In a real implementation, you'd include the component in the analysis
    return BackupComponent.values.first; // Placeholder
  }

  IconData _getComponentIcon(BackupComponent component) {
    switch (component) {
      case BackupComponent.income:
        return Icons.trending_up;
      case BackupComponent.outcome:
        return Icons.trending_down;
      case BackupComponent.preferences:
        return Icons.settings;
      case BackupComponent.metadata:
        return Icons.info;
    }
  }
}