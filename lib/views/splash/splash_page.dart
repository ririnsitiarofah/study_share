import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const HomePage();
              },
            ),
            (route) => false,
          );
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const SignInPage();
            },
          ),
          (route) => false,
        );
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 100,
              ),
              SizedBox(height: 36),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
