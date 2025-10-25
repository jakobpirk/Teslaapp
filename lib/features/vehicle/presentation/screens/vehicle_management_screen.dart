import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/vehicle_management_provider.dart';
import '../../../../core/data/models/vehicle_model_dto.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleManagementProvider>().loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myVehicles),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(context),
          ),
        ],
      ),
      body: Consumer<VehicleManagementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${AppLocalizations.of(context)!.error}: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadVehicles(),
                    child: Text(AppLocalizations.of(context)!.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasVehicles) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noVehiclesAdded),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVehicleDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addVehicle),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = provider.vehicles[index];
              final isSelected = provider.selectedVehicle?.id == vehicle.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(vehicle.displayName[0].toUpperCase()),
                  ),
                  title: Text(
                    vehicle.displayInfo,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vehicle.vin != null) Text('VIN: ${vehicle.vin}'),
                      if (vehicle.batteryCapacity != null)
                        Text('Battery: ${vehicle.batteryCapacity} kWh'),
                      Text(
                        vehicle.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: vehicle.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'select':
                          provider.selectVehicle(vehicle);
                          break;
                        case 'edit':
                          _showEditVehicleDialog(context, vehicle);
                          break;
                        case 'delete':
                          _confirmDelete(context, vehicle);
                          break;
                        case 'statistics':
                          _showStatistics(context, vehicle);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'select',
                        child: Text(AppLocalizations.of(context)!.select),
                      ),
                      PopupMenuItem(
                        value: 'statistics',
                        child: Text(AppLocalizations.of(context)!.viewStatistics),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppLocalizations.of(context)!.edit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                    ],
                  ),
                  onTap: () => provider.selectVehicle(vehicle),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final tessieIdController = TextEditingController();
    final displayNameController = TextEditingController();
    final modelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addVehicle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tessieIdController,
              decoration: const InputDecoration(
                labelText: 'Tessie Vehicle ID',
                hintText: 'Enter your Tessie vehicle ID',
              ),
            ),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., My Tesla',
              ),
            ),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model (optional)',
                hintText: 'e.g., Model 3',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tessieIdController.text.isEmpty ||
                  displayNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillRequiredFields)),
                );
                return;
              }

              final vehicleDto = CreateVehicleDto(
                tessieVehicleId: tessieIdController.text,
                displayName: displayNameController.text,
                model: modelController.text.isNotEmpty ? modelController.text : null,
              );

              final success = await context
                  .read<VehicleManagementProvider>()
                  .addVehicle(vehicleDto);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.vehicleAdded)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, VehicleModelDto vehicle) {
    final displayNameController = TextEditingController(text: vehicle.displayName);
    final modelController = TextEditingController(text: vehicle.model ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editVehicle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final updateDto = UpdateVehicleDto(
                displayName: displayNameController.text,
                model: modelController.text.isNotEmpty ? modelController.text : null,
              );

              final success = await context
                  .read<VehicleManagementProvider>()
                  .updateVehicle(vehicle.id, updateDto);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.vehicleUpdated)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VehicleModelDto vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVehicle),
        content: Text(AppLocalizations.of(context)!.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context
                  .read<VehicleManagementProvider>()
                  .deleteVehicle(vehicle.id);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.vehicleDeleted)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context, VehicleModelDto vehicle) async {
    final stats = await context
        .read<VehicleManagementProvider>()
        .getVehicleStatistics(vehicle.id);

    if (stats != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${vehicle.displayName} ${AppLocalizations.of(context)!.viewStatistics}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocalizations.of(context)!.totalSessions}: ${stats['statistics']['total_charging_sessions']}'),
              Text('${AppLocalizations.of(context)!.totalEnergy}: ${AppLocalizations.of(context)!.kWh(stats['statistics']['total_energy_kwh'].toString())}'),
              Text('${AppLocalizations.of(context)!.totalCost}: \$${stats['statistics']['total_cost']}'),
              Text('${AppLocalizations.of(context)!.avgCostPerSession}: \$${stats['statistics']['average_cost_per_session']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        ),
      );
    }
  }
}
