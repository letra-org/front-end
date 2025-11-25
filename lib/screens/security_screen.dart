import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SecurityScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const SecurityScreen({super.key, required this.onNavigate});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF2563EB),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => widget.onNavigate('settings'),
                    ),
                    Text(
                      appLocalizations.get('security_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(appLocalizations.get('change_password')),
                    subtitle: Text(appLocalizations.get('change_password_subtitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onNavigate('changePassword'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
