import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/user_settings_provider.dart';
import '../../../../core/data/models/electricity_provider_dto.dart';
import '../../../../providers/locale_provider.dart';

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
        title: Text(AppLocalizations.of(context)!.settings),
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
                  Text('${AppLocalizations.of(context)!.error}: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: Text(AppLocalizations.of(context)!.tryAgain),
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
              const SizedBox(height: 24),
              _buildLanguageSection(),
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
            Text(
              AppLocalizations.of(context)!.profile,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('${AppLocalizations.of(context)!.name}: ${profile.name}'),
            Text('${AppLocalizations.of(context)!.email}: ${profile.email}'),
            Text('${AppLocalizations.of(context)!.vehicles}: ${profile.activeVehiclesCount} active / ${profile.vehiclesCount} total'),
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
            Text(
              AppLocalizations.of(context)!.tessieApiKey,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  hasTessieKey ? Icons.check_circle : Icons.warning,
                  color: hasTessieKey ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(hasTessieKey ? AppLocalizations.of(context)!.configured : AppLocalizations.of(context)!.notConfigured),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _showTessieApiKeyDialog(context, provider),
                  child: Text(hasTessieKey ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.add),
                ),
                if (hasTessieKey) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _confirmRemoveTessieKey(context, provider),
                    child: Text(AppLocalizations.of(context)!.remove),
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
            Text(
              AppLocalizations.of(context)!.electricityProvider,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (selectedProvider != null) ...[
              Text('${AppLocalizations.of(context)!.electricityProvider}: ${selectedProvider.displayName}'),
              if (selectedProvider.description != null)
                Text(selectedProvider.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ] else ...[
              Text(AppLocalizations.of(context)!.selectProvider),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showProviderSelectionDialog(context, provider),
              child: Text(selectedProvider != null ? AppLocalizations.of(context)!.changeProvider : AppLocalizations.of(context)!.selectProvider),
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
        title: Text(AppLocalizations.of(context)!.tessieApiKey),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillRequiredFields)),
                );
                return;
              }

              final success = await provider.updateTessieApiKey(controller.text);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.apiKeyUpdated)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTessieKey(BuildContext context, UserSettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context)!.remove} ${AppLocalizations.of(context)!.tessieApiKey}'),
        content: Text(AppLocalizations.of(context)!.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.removeTessieApiKey();
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.apiKeyUpdated)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.remove),
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
        title: Text(AppLocalizations.of(context)!.selectProvider),
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
                      SnackBar(content: Text(AppLocalizations.of(context)!.providerUpdated)),
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
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.language,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(AppLocalizations.of(context)!.selectLanguage),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final localeProvider = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: const Text('🇺🇸'),
                onTap: () async {
                  await localeProvider.setLocale(const Locale('en'));
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Español'),
                leading: const Text('🇪🇸'),
                onTap: () async {
                  await localeProvider.setLocale(const Locale('es'));
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Deutsch'),
                leading: const Text('🇩🇪'),
                onTap: () async {
                  await localeProvider.setLocale(const Locale('de'));
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Français'),
                leading: const Text('🇫🇷'),
                onTap: () async {
                  await localeProvider.setLocale(const Locale('fr'));
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
