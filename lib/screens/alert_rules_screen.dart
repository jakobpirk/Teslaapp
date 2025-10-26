import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AlertRulesScreen extends StatefulWidget {
  const AlertRulesScreen({super.key});

  @override
  State<AlertRulesScreen> createState() => _AlertRulesScreenState();
}

class _AlertRulesScreenState extends State<AlertRulesScreen> {
  // Mock alert rules for demonstration
  final List<Map<String, dynamic>> rules = [
    {
      'id': '1',
      'name': 'Not Plugged In at Home',
      'type': 'not_plugged_in',
      'description': 'Alert when not plugged in after 9 PM on weekdays',
      'enabled': true,
      'priority': 2,
      'triggerCount': 5,
    },
    {
      'id': '2',
      'name': 'Low Battery',
      'type': 'battery_low',
      'description': 'Alert when battery drops below 20%',
      'enabled': true,
      'priority': 3,
      'triggerCount': 2,
    },
    {
      'id': '3',
      'name': 'Charging Complete',
      'type': 'charge_complete',
      'description': 'Notify when charging reaches 80%',
      'enabled': false,
      'priority': 1,
      'triggerCount': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Alert Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () => _showTemplatesDialog(context),
            tooltip: 'Templates',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                itemBuilder: (context, index) => _buildRuleCard(rules[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Alert Rules',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first alert',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule) {
    final isEnabled = rule['enabled'] as bool;
    final priority = rule['priority'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRuleIcon(rule['type'] as String),
                  color: isEnabled ? _getPriorityColor(priority) : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (rule['description'] != null)
                        Text(
                          rule['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      rule['enabled'] = value;
                    });
                  },
                  activeColor: _getPriorityColor(priority),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  _getPriorityLabel(priority),
                  _getPriorityColor(priority),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Triggered ${rule['triggerCount']}x',
                  Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _testRule(context, rule),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test'),
                  style: TextButton.styleFrom(foregroundColor: Colors.amber),
                ),
                TextButton.icon(
                  onPressed: () => _showEditRuleDialog(context, rule),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, rule),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getRuleIcon(String type) {
    switch (type) {
      case 'not_plugged_in':
        return Icons.power_off;
      case 'battery_low':
        return Icons.battery_alert;
      case 'charge_complete':
        return Icons.battery_full;
      case 'left_unlocked':
        return Icons.lock_open;
      case 'sentry_triggered':
        return Icons.security;
      case 'climate_on':
        return Icons.ac_unit;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return AppTheme.accentRed;
      case 2:
        return Colors.amber;
      case 1:
        return AppTheme.accentBlue;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'High Priority';
      case 2:
        return 'Medium Priority';
      case 1:
        return 'Low Priority';
      default:
        return 'Unknown';
    }
  }

  void _showTemplatesDialog(BuildContext context) {
    final templates = [
      'Not Plugged In at Home',
      'Low Battery Alert',
      'Charging Complete',
      'Left Unlocked',
      'Sentry Mode Triggered',
      'Climate On Too Long',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Rule Templates', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(Icons.add_circle_outline, color: AppTheme.accentBlue),
              title: Text(templates[index], style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${templates[index]} template selected')),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Add Alert Rule', style: TextStyle(color: Colors.white)),
        content: Text(
          'Rule creation form would go here.\n\n'
          'Features:\n'
          '• Select rule type\n'
          '• Configure conditions\n'
          '• Set notification preferences\n'
          '• Choose priority level',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule would be created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Edit Alert Rule', style: TextStyle(color: Colors.white)),
        content: Text(
          'Rule editing form would go here.\n\n'
          'Current name: ${rule['name']}',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule would be updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _testRule(BuildContext context, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Testing Rule', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Evaluating "${rule['name']}"...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Test Result', style: TextStyle(color: Colors.white)),
          content: Text(
            'Rule conditions not currently met.\n\n'
            'The rule would trigger if conditions are satisfied.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Rule?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${rule['name']}"?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                rules.remove(rule);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
