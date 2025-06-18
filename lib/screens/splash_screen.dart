import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 100, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'NiSha',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              local.splashSubtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}
