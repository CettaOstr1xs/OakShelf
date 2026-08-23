import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_bootstrap.dart';
import 'theme/theme.dart';
import 'theme/theme_controller.dart';
import 'services/google_books_service.dart';
import 'services/firebase_service.dart';
import 'screens/main_navigation_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase, resolving options from secrets.json when the
  // --dart-define values are missing (e.g. plain `flutter run` / IDE launch).
  try {
    await Firebase.initializeApp(
      options: await FirebaseBootstrap.resolveOptions(),
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize Firebase Service & login anonymously (handles offline mode)
  final firebaseService = FirebaseService();
  await firebaseService.signInAnonymously();

  // Initialize API service
  final apiService = GoogleBooksService();

  // Load persisted theme preference
  final themeController = ThemeController();
  await themeController.load();

  runApp(MyApp(
    firebaseService: firebaseService,
    apiService: apiService,
    themeController: themeController,
  ));
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;
  final ThemeController themeController;

  const MyApp({
    super.key,
    required this.firebaseService,
    required this.apiService,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'OakShelf',
          theme: OakShelfTheme.lightTheme,
          darkTheme: OakShelfTheme.darkTheme,
          themeMode: themeController.mode,
          debugShowCheckedModeBanner: false,
          home: MainNavigationContainer(
            firebaseService: firebaseService,
            apiService: apiService,
            themeController: themeController,
          ),
        );
      },
    );
  }
}
