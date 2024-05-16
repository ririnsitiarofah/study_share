import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyshare/firebase_options.dart';
import 'package:studyshare/views/splash/splash_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  log('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    log('notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('acaraSelesaiBox');

  await _configureLocalTimeZone();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (notificationResponse) {
      log('!===!=====================================================');
      log(notificationResponse.toString());
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
    ?..requestNotificationsPermission()
    ..requestExactAlarmsPermission();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseChatCore.instance.setConfig(
    const FirebaseChatCoreConfig(
      null,
      'room_chat',
      'user',
    ),
  );
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.system);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notifier,
      builder: (_, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          locale: const Locale('id', 'ID'),
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(),
          home: child,
        );
      },
      child: const SplashPage(),
    );
  }
}
