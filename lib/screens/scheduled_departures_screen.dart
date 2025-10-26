import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ScheduledDeparturesScreen extends StatefulWidget {
  const ScheduledDeparturesScreen({super.key});

  @override
  State<ScheduledDeparturesScreen> createState() => _ScheduledDeparturesScreenState();
}

class _ScheduledDeparturesScreenState extends State<ScheduledDeparturesScreen> {
  // Mock schedules for demonstration
  final List<Map<String, dynamic>> schedules = [
    {
      'id': '1',
      'time': '08:00',
      'days': 'Weekdays',
      'enabled': true,
      'climate': true,
      'charging': true,
      'targetTemp': 22.0,
      'targetCharge': 80,
    },
    {
      'id': '2',
      'time': '10:30',
      'days': 'Weekends',
      'enabled': false,
      'climate': true,
      'charging': false,
      'targetTemp': 20.0,
      'targetCharge': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Scheduled Departures'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add),
      ),
      body: schedules.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) => _buildScheduleCard(schedules[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Departures',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first schedule',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final isEnabled = schedule['enabled'] as bool;

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
                  Icons.alarm,
                  color: isEnabled ? AppTheme.accentBlue : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule['time'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? Colors.white : Colors.grey,
                        ),
                      ),
                      Text(
                        schedule['days'] as String,
                        style: TextStyle(
                          fontSize: 14,
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
                      schedule['enabled'] = value;
                    });
                  },
                  activeColor: AppTheme.accentBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureChips(schedule),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditScheduleDialog(context, schedule),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentBlue),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, schedule),
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

  Widget _buildFeatureChips(Map<String, dynamic> schedule) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (schedule['climate'] as bool)
          _buildChip(
            Icons.ac_unit,
            'Climate ${schedule['targetTemp']}°C',
            AppTheme.accentBlue,
          ),
        if (schedule['charging'] as bool && schedule['targetCharge'] != null)
          _buildChip(
            Icons.battery_charging_full,
            'Charge ${schedule['targetCharge']}%',
            AppTheme.accentGreen,
          ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Add Schedule', style: TextStyle(color: Colors.white)),
        content: Text(
          'Schedule creation form would go here.\n\n'
          'Features:\n'
          '• Set departure time\n'
          '• Select days of week\n'
          '• Configure preconditioning\n'
          '• Set charge target',
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
                const SnackBar(content: Text('Schedule would be created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Edit Schedule', style: TextStyle(color: Colors.white)),
        content: Text(
          'Schedule editing form would go here.\n\n'
          'Current time: ${schedule['time']}\n'
          'Current days: ${schedule['days']}',
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
                const SnackBar(content: Text('Schedule would be updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Schedule?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this departure schedule?',
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
                schedules.remove(schedule);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule deleted')),
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
