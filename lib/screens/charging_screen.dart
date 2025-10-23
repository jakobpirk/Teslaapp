import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../utils/app_theme.dart';

class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  double _chargeLimit = 80.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          final state = provider.vehicleState;
          final isCharging = state?.isCharging ?? false;
          final batteryLevel = state?.batteryLevel ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildBatteryDisplay(batteryLevel, isCharging, state),
                  const SizedBox(height: 32),
                  _buildChargingStatus(state),
                  const SizedBox(height: 24),
                  _buildChargingControls(provider, isCharging),
                  const SizedBox(height: 24),
                  _buildChargeLimitSlider(provider),
                  const SizedBox(height: 24),
                  _buildChargingInfo(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatteryDisplay(double batteryLevel, bool isCharging, state) {
    Color batteryColor = _getBatteryColor(batteryLevel);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            batteryColor.withOpacity(0.2),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: batteryLevel / 100,
                  strokeWidth: 12,
                  backgroundColor: batteryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                ),
              ),
              Column(
                children: [
                  Icon(
                    isCharging
                        ? Icons.battery_charging_full
                        : Icons.battery_full,
                    size: 40,
                    color: batteryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${batteryLevel.toInt()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: batteryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isCharging ? 'Charging' : 'Not Charging',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isCharging ? AppTheme.accentGreen : AppTheme.textSecondary,
            ),
          ),
          if (state?.batteryRange != null) ...[
            const SizedBox(height: 8),
            Text(
              '${state!.batteryRange!.toInt()} miles range',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale();
  }

  Color _getBatteryColor(double level) {
    if (level > 50) return AppTheme.accentGreen;
    if (level > 20) return AppTheme.accentYellow;
    return AppTheme.accentRed;
  }

  Widget _buildChargingStatus(state) {
    if (state?.isCharging != true) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem(
              'Charge Rate',
              '${state.chargeRate ?? 0} kW',
              Icons.bolt,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
            _buildStatusItem(
              'Status',
              state.chargingState ?? 'Unknown',
              Icons.info_outline,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChargingControls(VehicleProvider provider, bool isCharging) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            if (isCharging) {
              await provider.stopCharge();
              _showSnackBar('Charging stopped');
            } else {
              await provider.startCharge();
              _showSnackBar('Charging started');
            }
          } catch (e) {
            _showSnackBar('Failed: ${e.toString()}', isError: true);
          }
        },
        icon: Icon(isCharging ? Icons.stop : Icons.bolt),
        label: Text(
          isCharging ? 'Stop Charging' : 'Start Charging',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCharging ? AppTheme.accentRed : AppTheme.accentGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildChargeLimitSlider(VehicleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Charge Limit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_chargeLimit.toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryBlue,
                inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.2),
                thumbColor: AppTheme.primaryBlue,
                overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _chargeLimit,
                min: 50,
                max: 100,
                divisions: 10,
                label: '${_chargeLimit.toInt()}%',
                onChanged: (value) {
                  setState(() => _chargeLimit = value);
                },
                onChangeEnd: (value) {
                  provider.setLimit(value.toInt());
                  _showSnackBar('Charge limit set to ${value.toInt()}%');
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '50%',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  '100%',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended daily charge limit is 80% for battery health',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargingInfo(state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Charging Tips',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.wb_sunny,
              'Charge during off-peak hours for lower rates',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              Icons.battery_saver,
              'Keep charge between 20-80% for optimal battery health',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              Icons.local_fire_department,
              'Precondition battery in cold weather before charging',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.accentRed : AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
