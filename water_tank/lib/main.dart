import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:water_tank/authentication/authpage.dart';

var kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 86, 189, 230),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
          colorScheme: kColorScheme,
          scaffoldBackgroundColor: kColorScheme.primaryContainer,
          appBarTheme: const AppBarTheme().copyWith(
              backgroundColor: kColorScheme.onTertiaryContainer,
              foregroundColor: kColorScheme.primaryContainer),
          bottomNavigationBarTheme:
              const BottomNavigationBarThemeData().copyWith(
            backgroundColor: kColorScheme.onTertiaryContainer,
            unselectedItemColor: kColorScheme.onInverseSurface,
            selectedItemColor: kColorScheme.primaryContainer,
          )),
      home: const AuthPage(),
    );
  }
}
