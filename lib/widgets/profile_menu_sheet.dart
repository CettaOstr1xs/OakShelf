import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/google_books_service.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reading_challenge_screen.dart';
import '../screens/search_screen.dart';
import '../theme/theme.dart';

void showProfileMenuSheet({
  required BuildContext context,
  required FirebaseService firebaseService,
  required GoogleBooksService apiService,
  Function(int tabIndex)? onSelectTab,
}) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle Bar
            Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.oak.forestDeep,
                    theme.colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OakShelf Reader',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 15,
                              color: context.oak.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bibliophile • Level 4',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.oak.sky,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    color: Theme.of(context).colorScheme.outline,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(firebaseService: firebaseService),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'QUICK NAVIGATION',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Navigation Redirect Buttons
            _buildProfileNavButton(
              context: context,
              icon: Icons.menu_book_rounded,
              title: 'My Bookshelf',
              subtitle: 'View Reading Now, Wishlist & Custom Shelves',
              onTap: () {
                Navigator.pop(context);
                if (onSelectTab != null) onSelectTab(1);
              },
            ),
            _buildProfileNavButton(
              context: context,
              icon: Icons.emoji_events_rounded,
              title: '2026 Reading Challenge',
              subtitle: 'Track your annual reading goal & badges',
              iconColor: context.oak.accent,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadingChallengeScreen(
                      firebaseService: firebaseService,
                      apiService: apiService,
                    ),
                  ),
                );
              },
            ),
            _buildProfileNavButton(
              context: context,
              icon: Icons.format_quote_rounded,
              title: 'Saved Quotes',
              subtitle: 'Browse your collected book quotes',
              onTap: () {
                Navigator.pop(context);
                if (onSelectTab != null) onSelectTab(2);
              },
            ),
            _buildProfileNavButton(
              context: context,
              icon: Icons.search_rounded,
              title: 'Search Books',
              subtitle: 'Search online catalog & add books',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(
                      firebaseService: firebaseService,
                      apiService: apiService,
                    ),
                  ),
                );
              },
            ),
            _buildProfileNavButton(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Settings & Preferences',
              subtitle: 'Manage theme & app settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(firebaseService: firebaseService),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

Widget _buildProfileNavButton({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  final theme = Theme.of(context);
  final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 22),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.outline,
            size: 20,
          ),
        ),
      ),
    ),
  );
}
