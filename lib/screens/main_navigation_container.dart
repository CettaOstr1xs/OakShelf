import 'package:flutter/material.dart';
import '../services/google_books_service.dart';
import '../services/firebase_service.dart';
import 'dashboard_feed_screen.dart';
import 'home_screen.dart'; // Library / Bookshelves Screen
import 'quotes_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const MainNavigationContainer({
    super.key,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pages = [
      DashboardFeedScreen(
        firebaseService: widget.firebaseService,
        apiService: widget.apiService,
      ),
      HomeScreen(
        firebaseService: widget.firebaseService,
        apiService: widget.apiService,
      ),
      QuotesScreen(
        firebaseService: widget.firebaseService,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      // Center Plus button pressed -> Navigate to search overlay
      _openSearchScreen();
    } else if (index == 4) {
      // More button pressed -> Slide up the Goodreads style menu
      _showMoreMenu();
    } else {
      // Regular tab change with smooth slide animation
      final targetPageIndex = index > 2 ? index - 1 : index;
      setState(() {
        _currentIndex = targetPageIndex;
      });
      _pageController.animateToPage(
        targetPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openSearchScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          firebaseService: widget.firebaseService,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  void _showMoreMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Short Card
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        firebaseService: widget.firebaseService,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 2),
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),

                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anonymous Reader',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reader Tier: Bibliophile',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Menu Grid List
              ListTile(
                leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                title: Text('View Profile Stats', style: theme.textTheme.titleSmall),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        firebaseService: widget.firebaseService,
                      ),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey[100]),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
                title: Text('Settings & Database', style: theme.textTheme.titleSmall),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        firebaseService: widget.firebaseService,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Map current index in page view (which has 3 items)
    // to active state index on bottom bar
    int getSelectedBarIndex() {
      if (_currentIndex == 2) return 3; // Quotes is at index 3 in bar (due to Plus button at 2)
      return _currentIndex;
    }

    final activeBarIndex = getSelectedBarIndex();

    return Scaffold(
      body: Stack(
        children: [
          // Swipeable PageView container
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              physics: const BouncingScrollPhysics(),
              children: _pages,
            ),
          ),

          // Custom Floating Bottom Navigation Bar Container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // Floating Pill Backdrop Box
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 1. Home / Dashboard Feed
                        _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, activeBarIndex),
                        // 2. Library (Bookshelf)
                        _buildNavItem(1, Icons.menu_book_rounded, Icons.menu_book_outlined, activeBarIndex),
                        
                        // Spacer placeholder for the middle floating Plus button
                        const SizedBox(width: 52),
                        
                        // 4. Quotes
                        _buildNavItem(3, Icons.format_quote_rounded, Icons.format_quote_outlined, activeBarIndex),
                        // 5. More (Menu)
                        _buildNavItem(4, Icons.menu_rounded, Icons.menu_rounded, activeBarIndex),
                      ],
                    ),
                  ),

                  // Floating Center Plus Button (Taps Search Screen)
                  Positioned(
                    bottom: 28,
                    child: GestureDetector(
                      onTap: () => _onTabSelected(2),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onBackground, // Dark Charcoal
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.onBackground.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
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

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, int activeBarIndex) {
    final theme = Theme.of(context);
    final isSelected = activeBarIndex == index;

    return IconButton(
      onPressed: () => _onTabSelected(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onBackground.withOpacity(0.6),
          size: 26,
        ),
      ),
    );
  }
}
