import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_settings_provider.dart';
import '../../../../core/data/models/electricity_provider_dto.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserSettingsProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<UserSettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileSection(provider),
              const SizedBox(height: 24),
              _buildTessieApiKeySection(provider),
              const SizedBox(height: 24),
              _buildElectricityProviderSection(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(UserSettingsProvider provider) {
    final profile = provider.profile;
    if (profile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Name: ${profile.name}'),
            Text('Email: ${profile.email}'),
            Text('Vehicles: ${profile.activeVehiclesCount} active / ${profile.vehiclesCount} total'),
          ],
        ),
      ),
    );
  }

  Widget _buildTessieApiKeySection(UserSettingsProvider provider) {
    final hasTessieKey = provider.hasTessieApiKey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tessie API Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  hasTessieKey ? Icons.check_circle : Icons.warning,
                  color: hasTessieKey ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(hasTessieKey ? 'Configured' : 'Not configured'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _showTessieApiKeyDialog(context, provider),
                  child: Text(hasTessieKey ? 'Update' : 'Add'),
                ),
                if (hasTessieKey) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _confirmRemoveTessieKey(context, provider),
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectricityProviderSection(UserSettingsProvider provider) {
    final selectedProvider = provider.selectedProvider;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Electricity Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (selectedProvider != null) ...[
              Text('Provider: ${selectedProvider.displayName}'),
              if (selectedProvider.description != null)
                Text(selectedProvider.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ] else ...[
              const Text('No provider selected'),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showProviderSelectionDialog(context, provider),
              child: Text(selectedProvider != null ? 'Change Provider' : 'Select Provider'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTessieApiKeyDialog(BuildContext context, UserSettingsProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tessie API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'Enter your Tessie API key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an API key')),
                );
                return;
              }

              final success = await provider.updateTessieApiKey(controller.text);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API key updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTessieKey(BuildContext context, UserSettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove API Key'),
        content: const Text('Are you sure you want to remove your Tessie API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.removeTessieApiKey();
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API key removed')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showProviderSelectionDialog(
    BuildContext context,
    UserSettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Electricity Provider'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.availableProviders.length,
            itemBuilder: (context, index) {
              final p = provider.availableProviders[index];
              final isSelected = provider.selectedProvider?.id == p.id;

              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                ),
                title: Text(p.displayName),
                subtitle: p.description != null ? Text(p.description!) : null,
                onTap: () async {
                  final success = await provider.updateElectricityProvider(p.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Provider updated to ${p.displayName}')),
                    );
                  }
                },
              );
            },
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
}
