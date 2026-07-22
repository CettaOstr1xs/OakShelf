import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const SettingsScreen({
    super.key,
    required this.firebaseService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = widget.firebaseService.currentUid ?? 'Not authenticated';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Sync & Cloud Account
          _buildSectionHeader('Cloud Integration'),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Firebase Sync Status: Connected',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'User ID: $uid',
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your books and quotes are securely backed up in Cloud Firestore under this anonymous identifier.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Application Config
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme (Placeholder)',
            trailing: Switch(
              value: _darkMode,
              onChanged: (val) {
                setState(() {
                  _darkMode = val;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section: About
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: 'Bookery v1.0.0 (Firebase Edition)',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.code_rounded,
            title: 'Developer Mode',
            subtitle: 'Google Books REST Service Enabled',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onBackground.withOpacity(0.7)),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle != null ? Text(subtitle, style: theme.textTheme.bodySmall) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
