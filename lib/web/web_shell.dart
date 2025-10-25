import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Web shell that wraps the mobile app in an iPhone frame
/// This provides a realistic preview of the mobile app on web
class WebShell extends StatelessWidget {
  final Widget child;

  const WebShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Phone frame with app
            Expanded(
              child: Center(
                child: _buildPhoneFrame(),
              ),
            ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          const Icon(
            Icons.electric_car,
            color: Color(0xFF4A90E2),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'Tessie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A90E2).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Builder(
              builder: (context) => Row(
                children: [
                  const Icon(
                    Icons.phone_iphone,
                    color: Color(0xFF4A90E2),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.demoPreview,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildPhoneFrame() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 800,
        maxWidth: 400,
      ),
      child: AspectRatio(
        aspectRatio: 9 / 19.5, // iPhone aspect ratio
        child: DeviceFrame(
          device: Devices.ios.iPhone13ProMax,
          screen: child,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.demoPreviewMessage,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.downloadMobileApp,
              style: const TextStyle(
                color: Colors.white40,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.apple, size: 16, color: Colors.white54),
                  label: Text(
                    AppLocalizations.of(context)!.ios,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.android, size: 16, color: Colors.white54),
                  label: Text(
                    AppLocalizations.of(context)!.android,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
