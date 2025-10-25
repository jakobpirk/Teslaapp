import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../features/charging_stats/presentation/providers/charging_stats_provider.dart';
import '../core/domain/entities/charging_session_entity.dart';
import '../utils/app_theme.dart';

class ChargingDashboardScreen extends StatefulWidget {
  const ChargingDashboardScreen({super.key});

  @override
  State<ChargingDashboardScreen> createState() =>
      _ChargingDashboardScreenState();
}

class _ChargingDashboardScreenState extends State<ChargingDashboardScreen> {
  int _selectedSessionIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ChargingStatsProvider>(context, listen: false);
      provider.loadChargingSessions('default_vehicle');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text(AppLocalizations.of(context)!.chargingDashboard),
        actions: [
          Consumer<ChargingStatsProvider>(
            builder: (context, provider, _) {
              return TextButton.icon(
                onPressed: () {
                  provider.toggleMockData();
                  provider.loadChargingSessions('default_vehicle');
                },
                icon: Icon(
                  provider.useMockData ? Icons.analytics : Icons.cloud,
                  color: Colors.white70,
                ),
                label: Text(
                  provider.useMockData ? 'Mock Data' : 'Firebase',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChargingStatsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loading),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: AppTheme.accentRed),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context)!.error}: ${provider.error}',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadChargingSessions('default_vehicle'),
                    child: Text(AppLocalizations.of(context)!.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (provider.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.battery_charging_full,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No charging sessions found',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final sessions = provider.sessions;
          final selectedSession = sessions[_selectedSessionIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Stats
                _buildSummaryCards(provider),
                const SizedBox(height: 24),

                // Session Selector
                _buildSessionSelector(sessions),
                const SizedBox(height: 24),

                // Session Details Card
                _buildSessionDetailsCard(selectedSession),
                const SizedBox(height: 24),

                // Battery Percentage Chart
                _buildBatteryChartCard(selectedSession),
                const SizedBox(height: 24),

                // Charging Timeline
                _buildChargingTimelineCard(selectedSession),
                const SizedBox(height: 24),

                // Pricing Breakdown
                if (selectedSession.pricing != null)
                  _buildPricingCard(selectedSession),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(ChargingStatsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            AppLocalizations.of(context)!.totalSessions,
            '${provider.getSessionCount(days: 30)}',
            Icons.charging_station,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            AppLocalizations.of(context)!.totalEnergy,
            AppLocalizations.of(context)!.kWh(provider.getTotalEnergyAdded(days: 30).toStringAsFixed(1)),
            Icons.bolt,
            AppTheme.accentYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            AppLocalizations.of(context)!.totalCost,
            '\$${provider.getTotalCost(days: 30).toStringAsFixed(2)}',
            Icons.attach_money,
            AppTheme.accentGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSelector(List<ChargingSessionEntity> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.chargingDashboard,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isSelected = index == _selectedSessionIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSessionIndex = index;
                  });
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM d').format(session.startTime),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(session.startTime),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.kWh(session.energyAdded.toStringAsFixed(1)),
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDetailsCard(ChargingSessionEntity session) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session Details',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: session.isComplete
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : AppTheme.accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.isComplete ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    color: session.isComplete
                        ? AppTheme.accentGreen
                        : AppTheme.accentYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Start Time', dateFormat.format(session.startTime),
              Icons.access_time),
          if (session.endTime != null)
            _buildDetailRow(
                'End Time', dateFormat.format(session.endTime!), Icons.done),
          _buildDetailRow(
              'Duration',
              '${session.durationHours.toStringAsFixed(1)} hours',
              Icons.timer),
          _buildDetailRow(
              'Battery',
              '${session.startBatteryLevel.toStringAsFixed(0)}% → ${session.endBatteryLevel?.toStringAsFixed(0) ?? '?'}%',
              Icons.battery_charging_full),
          _buildDetailRow(AppLocalizations.of(context)!.totalEnergy,
              AppLocalizations.of(context)!.kWh(session.energyAdded.toStringAsFixed(1)), Icons.bolt),
          if (session.peakChargingRate != null)
            _buildDetailRow('Peak Rate',
                '${session.peakChargingRate!.toStringAsFixed(1)} kW', Icons.speed),
          _buildDetailRow('Avg Rate',
              '${session.averageChargingRate.toStringAsFixed(1)} kW', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryChartCard(ChargingSessionEntity session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battery Level Over Time',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < session.dataPoints.length) {
                          final point = session.dataPoints[value.toInt()];
                          return Text(
                            DateFormat('HH:mm').format(point.timestamp),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (session.dataPoints.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: session.dataPoints
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                            entry.key.toDouble(), entry.value.batteryLevel))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.accentGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentGreen.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingTimelineCard(ChargingSessionEntity session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charging Timeline',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...session.dataPoints
              .where((dp) => dp.isCharging)
              .take(10)
              .map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('HH:mm').format(point.timestamp),
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: point.batteryLevel / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${point.batteryLevel.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (point.chargeRate != null)
                    Text(
                      '${point.chargeRate!.toStringAsFixed(1)} kW',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPricingCard(ChargingSessionEntity session) {
    final pricing = session.pricing!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pricing Breakdown',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: \$${pricing.totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPricingInfo(
                  'Avg Rate',
                  '\$${pricing.pricePerKwh.toStringAsFixed(3)}/kWh',
                  Icons.show_chart,
                ),
              ),
              Expanded(
                child: _buildPricingInfo(
                  AppLocalizations.of(context)!.totalEnergy,
                  AppLocalizations.of(context)!.kWh(session.energyAdded.toStringAsFixed(1)),
                  Icons.bolt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hourly Breakdown',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: pricing.hourlyPrices
                    .map((p) => p.cost)
                    .reduce((a, b) => a > b ? a : b),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < pricing.hourlyPrices.length) {
                          return Text(
                            DateFormat('HH:mm')
                                .format(pricing.hourlyPrices[value.toInt()].hour),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: pricing.hourlyPrices
                    .asMap()
                    .entries
                    .map((entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.cost,
                              color: _getColorForPrice(entry.value.pricePerKwh),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        ))
                    .toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceLegend(),
        ],
      ),
    );
  }

  Widget _buildPricingInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getColorForPrice(double pricePerKwh) {
    if (pricePerKwh < 0.15) {
      return AppTheme.accentGreen; // Off-peak
    } else if (pricePerKwh < 0.25) {
      return AppTheme.accentYellow; // Mid-peak
    } else {
      return AppTheme.accentRed; // Peak
    }
  }

  Widget _buildPriceLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Off-Peak', AppTheme.accentGreen),
        const SizedBox(width: 16),
        _buildLegendItem('Mid-Peak', AppTheme.accentYellow),
        const SizedBox(width: 16),
        _buildLegendItem('Peak', AppTheme.accentRed),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
