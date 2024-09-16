import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:studyshare/core/utils/notifications_utils.dart';
import 'package:studyshare/firebase_options.dart';
import 'package:studyshare/views/home/calendar/event_detail_page.dart';
import 'package:studyshare/views/home/directories/directories_wrapper_page.dart';
import 'package:studyshare/views/splash/splash_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  if (message.data['channel'] == 'event') {
    await Firebase.initializeApp();
    await saveNotifications();
  }

  log("Handling a background message: ${message.messageId}");
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

void notificationTapForeground(NotificationResponse notificationResponse) {
  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (context) => EventDetailPage(
      idTugas: notificationResponse.payload!,
    ),
  ));
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Local Notification

  await _configureLocalTimeZone();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: notificationTapForeground,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
    ?..requestNotificationsPermission()
    ..requestExactAlarmsPermission();

  // Firebase Messaging

  final messaging = FirebaseMessaging.instance;

  if (kDebugMode) {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    log(fcmToken.toString());
  }

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  log('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.data}');

    final notification = message.notification;
    // final currentUser = FirebaseAuth.instance.currentUser;

    if (notification == null) return;

    // TODO: Uncomment this if you want to prevent notification from showing
    // if (message.data['id_pemilik'] == currentUser?.uid) return;

    if (message.data['channel'] == 'event') {
      var platformChannelSpecifics = const NotificationDetails(
        android: AndroidNotificationDetails(
          'event',
          'Acara',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data['id_acara'],
      );
    } else if (message.data['channel'] == 'chat') {
      var platformChannelSpecifics = const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat',
          'Chat',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data['id_kelas'],
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Chat

  FirebaseChatCore.instance.setConfig(
    const FirebaseChatCoreConfig(
      null,
      'room_chat',
      'user',
    ),
  );
  runApp(
    MyApp(
      onInitialLaunch: (context) async {
        final initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();

        if (initialMessage != null) {
          if (initialMessage.data['channel'] == 'event') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return EventDetailPage(
                  idTugas: initialMessage.data['id_acara'],
                );
              }),
            );
            return;
          } else if (initialMessage.data['channel'] == 'chat') {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return DirectoriesWrapperPage(
                  idKelas: initialMessage.data['id_kelas'],
                  namaKelas: initialMessage.notification!.title!,
                  idDirektori: null,
                  namaDirektori: null,
                  initialTab: 3,
                );
              }),
            );
            return;
          }
        }

        final notificationAppLaunchDetails =
            await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();

        if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return EventDetailPage(
                idTugas: notificationAppLaunchDetails!
                    .notificationResponse!.payload!,
              );
            }),
          );
          return;
        }
      },
    ),
  );
}

final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.system);

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.onInitialLaunch});

  final void Function(BuildContext context)? onInitialLaunch;

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
          navigatorKey: navigatorKey,
          builder: (context, child) {
            final currentBrightness = Theme.of(context).brightness;
            final lightColorScheme = Theme.of(context).colorScheme;
            final darkColorScheme = ThemeData.dark().colorScheme;

            return LoaderOverlay(
              useBackButtonInterceptor: true,
              duration: const Duration(milliseconds: 250),
              reverseDuration: const Duration(milliseconds: 250),
              overlayColor: switch (currentBrightness) {
                Brightness.dark => darkColorScheme.surface.withOpacity(0.5),
                Brightness.light => lightColorScheme.surface.withOpacity(0.5),
              },
              overlayWidgetBuilder: (_) {
                return const SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(),
                  ),
                );
              },
              child: child!,
            );
          },
          home: child,
        );
      },
      child: SplashPage(
        onInitialLaunch: onInitialLaunch,
      ),
    );
  }
}
