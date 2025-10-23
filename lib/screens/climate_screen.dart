import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../utils/app_theme.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  double _targetTemp = 22.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate Control'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          final state = provider.vehicleState;
          final isClimateOn = state?.isClimateOn ?? false;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTemperatureDisplay(state, isClimateOn),
                  const SizedBox(height: 32),
                  _buildTemperatureSlider(),
                  const SizedBox(height: 32),
                  _buildClimateToggle(provider, isClimateOn),
                  const SizedBox(height: 24),
                  _buildDefrostControls(provider),
                  const SizedBox(height: 24),
                  _buildSeatControls(provider),
                  const SizedBox(height: 24),
                  _buildSteeringWheelControl(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemperatureDisplay(state, bool isClimateOn) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGreen.withOpacity(0.2),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.thermostat,
            size: 64,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: 16),
          Text(
            '${_targetTemp.toInt()}°C',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isClimateOn ? 'Climate Active' : 'Climate Off',
            style: TextStyle(
              fontSize: 16,
              color: isClimateOn ? AppTheme.accentGreen : AppTheme.textSecondary,
            ),
          ),
          if (state?.insideTemp != null) ...[
            const SizedBox(height: 8),
            Text(
              'Inside: ${state!.insideTemp!.toInt()}°C',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale();
  }

  Widget _buildTemperatureSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Temperature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.accentGreen,
                inactiveTrackColor: AppTheme.accentGreen.withOpacity(0.2),
                thumbColor: AppTheme.accentGreen,
                overlayColor: AppTheme.accentGreen.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _targetTemp,
                min: 16,
                max: 28,
                divisions: 24,
                label: '${_targetTemp.toInt()}°C',
                onChanged: (value) {
                  setState(() => _targetTemp = value);
                },
                onChangeEnd: (value) {
                  context.read<VehicleProvider>().setClimateTemperature(value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '16°C',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  '28°C',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateToggle(VehicleProvider provider, bool isClimateOn) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (isClimateOn) {
            await provider.stopClimateControl();
            _showSnackBar('Climate stopped');
          } else {
            await provider.startClimateControl();
            _showSnackBar('Climate started');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isClimateOn ? AppTheme.accentRed : AppTheme.accentGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          isClimateOn ? 'Turn Off Climate' : 'Turn On Climate',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDefrostControls(VehicleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defrost',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.enableDefrost();
                      _showSnackBar('Defrost started');
                    },
                    icon: const Icon(Icons.ac_unit),
                    label: const Text('Start'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGreen,
                      side: const BorderSide(color: AppTheme.accentGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.disableDefrost();
                      _showSnackBar('Defrost stopped');
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatControls(VehicleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seat Climate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Front Left Seat',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Seat 0 = Driver, Level 3 = High
                      provider.setHeater(0, 3);
                      _showSnackBar('Seat heating started');
                    },
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Heat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.setCooler(0, 3);
                      _showSnackBar('Seat cooling started');
                    },
                    icon: const Icon(Icons.ac_unit),
                    label: const Text('Cool'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteeringWheelControl(VehicleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Steering Wheel Heater',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.enableWheelHeater();
                      _showSnackBar('Steering wheel heater started');
                    },
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Start'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.disableWheelHeater();
                      _showSnackBar('Steering wheel heater stopped');
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentGreen,
                      side: const BorderSide(color: AppTheme.accentGreen),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
