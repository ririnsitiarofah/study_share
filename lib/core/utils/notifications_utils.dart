import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:timezone/timezone.dart';

Future<void> saveNotifications(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SignInPage()));
      return;
    }

    final snapshotMember = await FirebaseFirestore.instance
        .collection('member_kelas')
        .where('id_user', isEqualTo: user.uid)
        .get();

    final kelasIds =
        snapshotMember.docs.map((e) => e.data()['id_kelas'] as String).toList();

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
              channelDescription: 'your channel description',
              importance: Importance.max,
              priority: Priority.high,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  } catch (e, stackTrace) {
    log(e.toString(), error: e, stackTrace: stackTrace);
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
  return TZDateTime.from(date, local);
}
