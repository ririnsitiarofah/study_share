import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/core/utils/notifications_utils.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.onInitialLaunch});

  final void Function(BuildContext context)? onInitialLaunch;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await saveNotifications(context);

      if (FirebaseAuth.instance.currentUser != null) {
        final memberKelas = await FirebaseFirestore.instance
            .collection('member_kelas')
            .where('id_user', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get();

        await Future.wait(
          memberKelas.docs.map((member) async {
            await FirebaseMessaging.instance
                .subscribeToTopic('chat-${member.data()['id_kelas']}');
          }),
        );

        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const HomePage();
            },
          ),
          (route) => false,
        );

        if (widget.onInitialLaunch != null) {
          widget.onInitialLaunch!(context);
        }
        return;
      }

      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const SignInPage();
          },
        ),
        (route) => false,
      );
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
