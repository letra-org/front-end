import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SponsorsScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const SponsorsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
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
                      onPressed: () => onNavigate('settings'),
                    ),
                    Text(
                      appLocalizations.get('sponsors_title'),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  appLocalizations.get('sponsors_thank_you'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(appLocalizations.get('sponsors_description')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
