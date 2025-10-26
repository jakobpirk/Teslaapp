import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';

class CO2StatisticsScreen extends StatefulWidget {
  const CO2StatisticsScreen({super.key});

  @override
  State<CO2StatisticsScreen> createState() => _CO2StatisticsScreenState();
}

class _CO2StatisticsScreenState extends State<CO2StatisticsScreen> {
  // Mock data for demonstration
  final double totalCO2Saved = 45.6; // kg
  final double totalEnergyKwh = 342.5;
  final double renewablePercentage = 62.3;
  final double avgCO2Intensity = 245.0; // g/kWh
  final double gridAvgIntensity = 400.0; // g/kWh

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('CO2 Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement actual data refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildSavingsCard(),
              const SizedBox(height: 16),
              _buildRenewableChart(),
              const SizedBox(height: 16),
              _buildMonthlyChart(),
              const SizedBox(height: 16),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final improvementPercentage =
        ((gridAvgIntensity - avgCO2Intensity) / gridAvgIntensity * 100);

    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: AppTheme.accentGreen, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Your Impact',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatRow('Total Energy', '${totalEnergyKwh.toStringAsFixed(1)} kWh', Colors.blue),
            const SizedBox(height: 12),
            _buildStatRow('CO2 Saved', '${totalCO2Saved.toStringAsFixed(1)} kg', AppTheme.accentGreen),
            const SizedBox(height: 12),
            _buildStatRow('Renewable Energy', '${renewablePercentage.toStringAsFixed(1)}%', Colors.amber),
            const SizedBox(height: 12),
            _buildStatRow(
              'Improvement vs Grid',
              '${improvementPercentage.toStringAsFixed(0)}% cleaner',
              AppTheme.accentGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsCard() {
    final kmDriven = (totalEnergyKwh / 15) * 100; // Approx km driven
    final treesEquivalent = (totalCO2Saved / 20).floor(); // ~20kg CO2 per tree/year

    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environmental Impact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactItem(
                    Icons.directions_car,
                    '${kmDriven.toStringAsFixed(0)} km',
                    'Distance Driven',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildImpactItem(
                    Icons.park,
                    '$treesEquivalent trees',
                    'CO2 Offset',
                    AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRenewableChart() {
    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Energy Sources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: renewablePercentage,
                      title: '${renewablePercentage.toStringAsFixed(0)}%',
                      color: AppTheme.accentGreen,
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 100 - renewablePercentage,
                      title: '${(100 - renewablePercentage).toStringAsFixed(0)}%',
                      color: Colors.grey[700],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(AppTheme.accentGreen, 'Renewable'),
                _buildLegendItem(Colors.grey[700]!, 'Non-Renewable'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    // Mock monthly data
    final monthlyData = [
      ('Jan', 35.2),
      ('Feb', 42.1),
      ('Mar', 38.5),
      ('Apr', 45.2),
      ('May', 52.3),
      ('Jun', 48.9),
    ];

    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Energy Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 60,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= monthlyData.length) return const Text('');
                          return Text(
                            monthlyData[value.toInt()].$1,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyData
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.$2,
                              color: AppTheme.accentBlue,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      {'icon': Icons.wb_sunny, 'title': 'Charge during daylight', 'desc': 'Solar production is highest'},
      {'icon': Icons.schedule, 'title': 'Use off-peak hours', 'desc': 'Grid is cleaner at night'},
      {'icon': Icons.battery_charging_full, 'title': 'Optimize charge level', 'desc': 'Don\'t overcharge unnecessarily'},
    ];

    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tips to Reduce CO2',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(tip['icon'] as IconData, color: AppTheme.accentGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              tip['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('About CO2 Statistics', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your charging sessions are analyzed for carbon emissions. '
          'By charging when renewable energy is abundant, you can reduce your environmental impact.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
