import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/status_card.dart';
import '../widgets/action_button.dart';
import 'climate_screen.dart';
import 'charging_screen.dart';
import 'charging_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().refreshVehicleState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<VehicleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.vehicleState == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final state = provider.vehicleState;

            return RefreshIndicator(
              onRefresh: () => provider.refreshVehicleState(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state?.displayName ?? 'Tesla'),
                      const SizedBox(height: 24),
                      _buildVehicleImage(),
                      const SizedBox(height: 24),
                      _buildStatusGrid(state, provider),
                      const SizedBox(height: 24),
                      _buildQuickActions(context, state, provider),
                      const SizedBox(height: 24),
                      _buildControlSections(context, state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String vehicleName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.myTesla,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vehicleName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildVehicleImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 120,
          color: AppTheme.textPrimary.withOpacity(0.3),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(delay: 200.ms);
  }

  Widget _buildStatusGrid(state, VehicleProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatusCard(
          title: AppLocalizations.of(context)!.battery,
          value: state?.batteryLevelString ?? 'N/A',
          icon: Icons.battery_charging_full,
          iconColor: _getBatteryColor(state?.batteryLevel),
        ),
        StatusCard(
          title: AppLocalizations.of(context)!.range,
          value: state?.rangeString ?? 'N/A',
          icon: Icons.route,
          iconColor: AppTheme.accentGreen,
        ),
        StatusCard(
          title: AppLocalizations.of(context)!.status,
          value: state?.state ?? 'Unknown',
          icon: Icons.info_outline,
          iconColor: state?.isOnline == true
              ? AppTheme.accentGreen
              : AppTheme.accentYellow,
        ),
        StatusCard(
          title: AppLocalizations.of(context)!.climate,
          value: state?.isClimateOn == true ? 'On' : 'Off',
          icon: Icons.ac_unit,
          iconColor: state?.isClimateOn == true
              ? AppTheme.accentGreen
              : AppTheme.textSecondary,
        ),
      ],
    );
  }

  Color _getBatteryColor(double? level) {
    if (level == null) return AppTheme.textSecondary;
    if (level > 50) return AppTheme.accentGreen;
    if (level > 20) return AppTheme.accentYellow;
    return AppTheme.accentRed;
  }

  Widget _buildQuickActions(
      BuildContext context, state, VehicleProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: state?.isLocked == true ? AppLocalizations.of(context)!.unlock : AppLocalizations.of(context)!.lock,
                icon: state?.isLocked == true
                    ? Icons.lock_outline
                    : Icons.lock_open,
                onPressed: () => _handleLockToggle(provider, state),
                isActive: state?.isLocked == false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                label: AppLocalizations.of(context)!.flashLights,
                icon: Icons.lightbulb_outline,
                onPressed: () => _handleFlashLights(provider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                label: AppLocalizations.of(context)!.honkHorn,
                icon: Icons.volume_up,
                onPressed: () => _handleHonk(provider),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlSections(BuildContext context, state) {
    return Column(
      children: [
        _buildSectionCard(
          AppLocalizations.of(context)!.climateControl,
          AppLocalizations.of(context)!.climateControlDesc,
          Icons.thermostat,
          AppTheme.accentGreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClimateScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          AppLocalizations.of(context)!.charging,
          AppLocalizations.of(context)!.chargingDesc,
          Icons.ev_station,
          AppTheme.primaryBlue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChargingScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          AppLocalizations.of(context)!.chargingDashboard,
          AppLocalizations.of(context)!.chargingDashboardDesc,
          Icons.analytics,
          AppTheme.accentYellow,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChargingDashboardScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          AppLocalizations.of(context)!.sentryMode,
          state?.isSentryMode == true ? AppLocalizations.of(context)!.sentryModeActive : AppLocalizations.of(context)!.sentryModeInactive,
          Icons.security,
          state?.isSentryMode == true
              ? AppTheme.accentGreen
              : AppTheme.textSecondary,
          () => _handleSentryToggle(context),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  void _handleLockToggle(VehicleProvider provider, state) async {
    try {
      if (state?.isLocked == true) {
        await provider.unlock();
        _showSnackBar(AppLocalizations.of(context)!.vehicleUnlocked);
      } else {
        await provider.lock();
        _showSnackBar(AppLocalizations.of(context)!.vehicleLocked);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.failedWithError(e.toString()), isError: true);
    }
  }

  void _handleFlashLights(VehicleProvider provider) async {
    try {
      await provider.flash();
      _showSnackBar(AppLocalizations.of(context)!.lightsFlashed);
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.failedWithError(e.toString()), isError: true);
    }
  }

  void _handleHonk(VehicleProvider provider) async {
    try {
      await provider.honk();
      _showSnackBar(AppLocalizations.of(context)!.hornHonked);
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.failedWithError(e.toString()), isError: true);
    }
  }

  void _handleSentryToggle(BuildContext context) async {
    try {
      await context.read<VehicleProvider>().toggleSentryMode();
      _showSnackBar(AppLocalizations.of(context)!.sentryModeToggled);
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.failedWithError(e.toString()), isError: true);
    }
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
