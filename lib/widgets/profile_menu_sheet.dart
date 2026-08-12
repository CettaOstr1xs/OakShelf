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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [OakShelfTheme.forestDeep, OakShelfTheme.primaryColor],
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
                            const Icon(
                              Icons.stars_rounded,
                              size: 15,
                              color: OakShelfTheme.accentGoldColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bibliophile • Level 4',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: OakShelfTheme.skyColor,
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
                    color: Colors.grey[400],
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
                color: Colors.grey[500],
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
              iconColor: Colors.amber[700],
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
      color: OakShelfTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
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
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[400],
            size: 20,
          ),
        ),
      ),
    ),
  );
}
