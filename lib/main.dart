import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'services/google_books_service.dart';
import 'services/firebase_service.dart';
import 'screens/main_navigation_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using CLI-generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization notice: $e');
  }

  // Initialize Firebase Service & login anonymously (handles offline mode)
  final firebaseService = FirebaseService();
  await firebaseService.signInAnonymously();

  // Initialize API service
  final apiService = GoogleBooksService();

  runApp(MyApp(
    firebaseService: firebaseService,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  final GoogleBooksService apiService;

  const MyApp({
    super.key,
    required this.firebaseService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookery',
      theme: BookeryTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: MainNavigationContainer(
        firebaseService: firebaseService,
        apiService: apiService,
      ),
    );
  }
}
