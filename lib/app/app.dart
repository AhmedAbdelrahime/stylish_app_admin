import 'package:flutter/material.dart';
import 'package:hungry/core/navigation/app_navigator.dart';
import 'package:hungry/pages/splash_screen.dart';

class HungryApp extends StatelessWidget {
  const HungryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      theme: ThemeData(splashColor: Colors.transparent),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
