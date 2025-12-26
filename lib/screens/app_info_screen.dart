import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AppInfoScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const AppInfoScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Container(
            color: const Color(0xFF1E88E5),
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
                      appLocalizations.get('app_info_title'),
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
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack( 
                    alignment: Alignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                        height: 180,
                      ),

                      // Chữ Letra
                      const Positioned(
                        bottom: 5,
                        child: Text(
                          'Letra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black54,
                                offset: Offset(0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ), 
                
                const SizedBox(height: 8),
                Center(child: Text(appLocalizations.get('version'))),
                const SizedBox(height: 32),
                Text(
                  appLocalizations.get('about_letra_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  appLocalizations.get('about_letra_body'),
                ),
                const SizedBox(height: 24),
                Text(
                  appLocalizations.get('copyright'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
