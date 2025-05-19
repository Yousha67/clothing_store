import 'package:clothing_store/auth/forget_pass.dart';
import 'package:clothing_store/auth/login.dart';
import 'package:clothing_store/screens/home.dart';
import 'package:clothing_store/screens/root_navigator.dart';
import 'package:clothing_store/state_management/cart_provider.dart';
import 'package:clothing_store/state_management/checkout_provider.dart';
import 'package:clothing_store/state_management/reward_provider.dart';
import 'package:clothing_store/state_management/theme_ptovider.dart';
import 'package:clothing_store/state_management/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'auth/app_content.dart';
import 'auth/signup.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = publishablekey; // Set your Stripe public key
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => RewardProvider()),
        ChangeNotifierProvider(create: (context) => CheckoutProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Show loading screen while theme is being loaded
        if (!themeProvider.isInitialized) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ladies Collection',
          theme: ThemeData(
            primarySwatch: Colors.pink,
            appBarTheme:  AppBarTheme(
              backgroundColor: themeProvider.isDarkMode?Colors.black38:Colors.pink[200],
              elevation: 4,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            buttonTheme: const ButtonThemeData(
              buttonColor: Colors.pink,
              textTheme: ButtonTextTheme.primary,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
          ),
          home: const RootNavigator(),
          routes: {
            '/homepage': (context) =>  HomeScreen(),
            '/login': (context) =>  AdvancedLoginScreen(),
            '/signup': (context) =>  AdvancedSignupScreen(),
            '/forgot-password': (context) =>  ForgetPasswordScreen(),
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Page not found')),
              ),
            );
          },
        );
      },
    );
  }
}
