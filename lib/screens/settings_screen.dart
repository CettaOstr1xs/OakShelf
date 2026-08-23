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
  final _restoreController = TextEditingController();
  bool _isRestoring = false;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = widget.firebaseService.currentUid ?? 'Not authenticated';
    final storageId = widget.firebaseService.storageOwnerId;
    final signedIn = widget.firebaseService.currentUid != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: NatureBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NatureHeroCard(
              startColor: theme.colorScheme.secondary,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    color: context.oak.accent,
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
                            color: context.oak.sky,
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
              color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          signedIn
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: signedIn ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          signedIn
                              ? 'Firebase Sync Status: Connected'
                              : 'Firebase Sync Status: Offline mode',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'Auth UID: $uid',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Storage ID: $storageId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your books and quotes are stored in Cloud Firestore under '
                      'the Storage ID above. It is pinned on this device, so '
                      'anonymous session resets no longer hide your library.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Library Recovery
            _buildSectionHeader('Library Recovery'),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restore_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Restore from a previous account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If your books were saved under an older anonymous account '
                      '(Firebase Console > Authentication > Users), paste its UID '
                      'here to copy that library into this device.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restoreController,
                      decoration: const InputDecoration(
                        labelText: 'Previous Account ID (UID)',
                        hintText: 'e.g. xK9d... from Firebase Console',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRestoring ? null : _runRestore,
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: const Text('Restore Library'),
                      ),
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
              subtitle: 'OakShelf v1.0.0 (Firebase Edition)',
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

  Future<void> _runRestore() async {
    final legacyId = _restoreController.text.trim();
    final theme = Theme.of(context);
    setState(() => _isRestoring = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await widget.firebaseService.restoreFromOwner(legacyId);
      if (result.ok && result.booksCopied + result.quotesCopied > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${result.booksCopied} books and '
              '${result.quotesCopied} quotes!',
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _restoreController.clear();
      } else if (result.ok) {
        _showRestoreProblem(
          messenger,
          'Nothing was found under "$legacyId" on the Firestore server. '
          'Double-check the UID (Firebase Console → Authentication → Users) '
          'and that users/$legacyId/books has documents in Firestore.',
          errorColor: theme.colorScheme.error,
        );
      } else {
        _showRestoreProblem(
          messenger,
          result.errors.join('\n'),
          errorColor: theme.colorScheme.error,
        );
      }
    } catch (e) {
      _showRestoreProblem(
        messenger,
        e.toString(),
        errorColor: theme.colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showRestoreProblem(
    ScaffoldMessengerState messenger,
    String detail, {
    required Color errorColor,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Restore problem: $detail'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
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
      color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
