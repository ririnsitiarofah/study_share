import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';

Future<void> saveNotifications(
    [BuildContext? context, bool subscribe = false]) async {
  try {
    log('Saving local notifications...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context == null) return;

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SignInPage()));
      return;
    }

    final snapshotMember = await FirebaseFirestore.instance
        .collection('member_kelas')
        .where('id_user', isEqualTo: user.uid)
        .get();

    final kelasIds = await Future.wait(snapshotMember.docs.map(
      (doc) async {
        try {
          if (subscribe) {
            await FirebaseMessaging.instance
                .subscribeToTopic("acara-${doc.data()['id_kelas']}");
            await FirebaseMessaging.instance
                .subscribeToTopic('chat-${doc.data()['id_kelas']}');
          }
        } catch (e, s) {
          log(e.toString(), error: e, stackTrace: s);
        }
        return doc.data()['id_kelas'] as String;
      },
    ).toList());

    if (kelasIds.isEmpty) {
      return;
    }

    final snapshotAcara = await FirebaseFirestore.instance
        .collection('acara')
        .where('id_kelas', whereIn: kelasIds)
        .get();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final requests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (var element in requests) {
      flutterLocalNotificationsPlugin.cancel(element.id);
    }

    for (final doc in snapshotAcara.docs) {
      final date = (doc['tanggal_mulai'] as Timestamp).toDate();
      if (date.isBefore(DateTime.now())) {
        continue;
      }

      for (var i = 0; i < 3; i++) {
        final title = doc['judul'] as String;
        final anHourBefore = date.subtract(const Duration(hours: 1));
        final aDayBefore = date.subtract(const Duration(days: 1));

        if (i == 1 && anHourBefore.isBefore(DateTime.now())) continue;

        if (i == 2 && aDayBefore.isBefore(DateTime.now())) continue;

        await flutterLocalNotificationsPlugin.zonedSchedule(
          switch (i) {
            0 => doc.id.hashCode,
            1 => ('anHour-${doc.id}').hashCode,
            2 => ('aDay-${doc.id}').hashCode,
            _ => throw Exception('Invalid index: $i'),
          },
          switch (i) {
            0 => title,
            1 => '1 jam lagi sebelum $title',
            2 => 'Besok ada $title',
            _ => throw Exception('Invalid index: $i'),
          },
          _formatDate(doc['tanggal_mulai']),
          _parseDate(
            switch (i) {
              0 => date,
              1 => anHourBefore,
              2 => aDayBefore,
              _ => throw Exception('Invalid index: $i'),
            },
          ),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'event',
              'Acara',
              importance: Importance.max,
              priority: Priority.high,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: doc.id,
        );
      }
    }

    log('Local notifications saved!');
  } catch (e, stackTrace) {
    if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context!).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi tidak diizinkan. Silakan aktifkan notifikasi di pengaturan aplikasi.',
          ),
        ),
      );
      return;
    }
    log(e.toString(), error: e, stackTrace: stackTrace);

    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal memuat data. Silakan coba lagi.'),
      ),
    );
  }
}

Future<void> resetNotifications([BuildContext? context]) async {
  try {
    log('Resetting local notifications...');

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final requests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (var element in requests) {
      flutterLocalNotificationsPlugin.cancel(element.id);
    }

    FirebaseMessaging.instance.deleteToken();

    log('Local notifications reset!');
  } catch (e, stackTrace) {
    if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context!).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi tidak diizinkan. Silakan aktifkan notifikasi di pengaturan aplikasi.',
          ),
        ),
      );
      return;
    }
    log(e.toString(), error: e, stackTrace: stackTrace);

    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal memuat data. Silakan coba lagi.'),
      ),
    );
  }
}

String? _formatDate(Timestamp timestamp) {
  return DateFormat.Hm().format(timestamp.toDate());
}

TZDateTime _parseDate(DateTime date) {
  initializeTimeZones();
  return TZDateTime.from(date, local);
}
