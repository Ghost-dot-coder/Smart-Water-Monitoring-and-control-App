import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:water_tank/authentication/signin.dart';
import 'package:water_tank/pages/homescreen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Show loading
        }
        if (snapshot.hasData) {
          return const HomeScreen(); // Auto-login if user is already authenticated
        }
        return const SignInPage(); // Show login/signup options if not logged in
      },
    );
  }
}
