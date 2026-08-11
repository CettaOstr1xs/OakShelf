import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/nature_ui.dart';
import '../theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const SettingsScreen({super.key, required this.firebaseService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = widget.firebaseService.currentUid ?? 'Not authenticated';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: NatureBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NatureHeroCard(
              startColor: BookeryTheme.oceanBlueColor,
              endColor: BookeryTheme.primaryColor,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    color: BookeryTheme.accentGoldColor,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your library travels with you',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Books, quotes, and goals sync through Firestore.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: BookeryTheme.skyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section: Sync & Cloud Account
            _buildSectionHeader('Cloud Integration'),
            Card(
              elevation: 0,
              color: BookeryTheme.surfaceColor,
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
                        const Icon(
                          Icons.cloud_done_rounded,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Firebase Sync Status: Connected',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'User ID: $uid',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
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
              subtitle: 'Hardcover catalog service enabled',
              onTap: () {},
            ),
          ],
        ),
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
      color: BookeryTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.onBackground.withOpacity(0.7),
        ),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle != null
            ? Text(subtitle, style: theme.textTheme.bodySmall)
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
