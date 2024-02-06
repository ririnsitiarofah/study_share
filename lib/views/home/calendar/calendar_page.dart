import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:studyshare/views/home/calendar/add_event_page.dart';
import 'package:studyshare/views/home/calendar/event_detail_page.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendarController = CalendarController();

  final _events = _EventDataSource(source: <Map<String, dynamic>>[]);

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SfCalendar(
          controller: _calendarController,
          dataSource: _events,
          loadMoreWidgetBuilder: (context, loadMoreAppointments) {
            return FutureBuilder(
              future: loadMoreAppointments(),
              builder: (context, snapShot) {
                return Container(
                  height: _calendarController.view == CalendarView.schedule
                      ? 50
                      : double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            );
          },
          view: CalendarView.month,
          showDatePickerButton: true,
          monthViewSettings: const MonthViewSettings(
            showAgenda: true,
          ),
          allowedViews: const [
            CalendarView.day,
            CalendarView.week,
            CalendarView.month,
            CalendarView.schedule,
          ],
          onTap: (calendarTapDetails) {
            if (calendarTapDetails.targetElement ==
                CalendarElement.appointment) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                    idTugas: calendarTapDetails.appointments!.first['id'],
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_box_rounded,
        shape: Theme.of(context).floatingActionButtonTheme.shape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
            ),
        activeIcon: Icons.close,
        childrenButtonSize: const Size.square(48),
        spaceBetweenChildren: 16,
        childPadding: const EdgeInsets.all(4),
        children: [
          SpeedDialChild(
            label: ('Acara'),
            onTap: () => _handleAddEvent(context, 'acara'),
            child: const Icon(Icons.event),
          ),
          SpeedDialChild(
            label: ("Tugas"),
            onTap: () => _handleAddEvent(context, 'tugas'),
            child: const Icon(Icons.task_alt),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddEvent(BuildContext context, String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddEventPage(
          initialDate: _calendarController.selectedDate ?? DateTime.now(),
          initialType: type,
          onEventAdded: (appointment, kelas, eventType) async {
            try {
              final user = FirebaseAuth.instance.currentUser!;
              final eventMap = {
                'id_pemilik': user.uid,
                'id_kelas': kelas['id'],
                'judul': appointment.subject,
                'tanggal_mulai': appointment.startTime,
                'tanggal_selesai': appointment.endTime,
                'ulangi': appointment.recurrenceRule == null
                    ? 'none'
                    : switch (SfCalendar.parseRRule(
                            appointment.recurrenceRule!, appointment.startTime)
                        .recurrenceType) {
                        RecurrenceType.daily => 'harian',
                        RecurrenceType.weekly => 'mingguan',
                        RecurrenceType.monthly => 'bulanan',
                        RecurrenceType.yearly => 'tahunan',
                      },
                'seharian': appointment.isAllDay,
                'tipe': eventType,
                'warna': appointment.color.value,
                'deskripsi': appointment.notes,
                'terakhir_diubah': Timestamp.now(),
                'tanggal_dibuat': Timestamp.now(),
              };

              await FirebaseFirestore.instance
                  .collection('acara')
                  .add(eventMap);

              Navigator.pop(context);

              setState(() {
                _events.appointments.add(eventMap);
              });
            } catch (e, stackTrace) {
              log(e.toString(), error: e, stackTrace: stackTrace);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Gagal menambahkan acara, silahkan coba lagi!"),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource({
    required this.source,
  });

  final List<Map<String, dynamic>> source;

  @override
  List<Map<String, dynamic>> get appointments => source;

  @override
  DateTime getStartTime(int index) {
    return (appointments[index]['tanggal_mulai'] as Timestamp).toDate();
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments[index]['tanggal_selesai'] as Timestamp).toDate();
  }

  @override
  String getSubject(int index) {
    return appointments[index]['judul'];
  }

  @override
  Color getColor(int index) {
    return Color(appointments[index]['warna']);
  }

  @override
  bool isAllDay(int index) {
    return appointments[index]['seharian'];
  }

  @override
  Future<void> handleLoadMore(DateTime startDate, DateTime endDate) async {
    try {
      final meetings = <Map<String, dynamic>>[];
      final date = DateTime(startDate.year, startDate.month, startDate.day);
      final appEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final user = FirebaseAuth.instance.currentUser!;
      final snapshotMember = await FirebaseFirestore.instance
          .collection('member_kelas')
          .where('id_user', isEqualTo: user.uid)
          .get();

      final kelasIds = snapshotMember.docs
          .map((e) => e.data()['id_kelas'] as String)
          .toList();

      final snapshotAcara = await FirebaseFirestore.instance
          .collection('acara')
          .where('id_kelas', whereIn: kelasIds)
          .where('tanggal_mulai', isGreaterThanOrEqualTo: date)
          .where('tanggal_mulai', isLessThanOrEqualTo: appEndDate)
          .get();

      for (final doc in snapshotAcara.docs) {
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        if (appointments.any((appointment) => mapEquals(appointment, data))) {
          continue;
        }
        meetings.add(data);
      }

      appointments.addAll(meetings);
      notifyListeners(CalendarDataSourceAction.add, meetings);
    } catch (e, stackTrace) {
      log(e.toString(), error: e, stackTrace: stackTrace);
    }
  }
}
