import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  void initState() {
    Hive.box('acaraSelesaiBox').listenable().addListener(() {
      _events.notifyListeners(CalendarDataSourceAction.reset, []);
    });
    super.initState();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            CalendarView.schedule,
            CalendarView.day,
            CalendarView.week,
            CalendarView.month,
          ],
          onTap: (calendarTapDetails) {
            if (calendarTapDetails.targetElement ==
                CalendarElement.appointment) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                    idTugas: calendarTapDetails.appointments!.first['id'],
                    onUpdated: (eventData) {
                      try {
                        _events.appointments
                            .remove(calendarTapDetails.appointments!.first);
                        _events.appointments.add(eventData);

                        _events.notifyListeners(CalendarDataSourceAction.remove,
                            [calendarTapDetails.appointments!.first]);
                        _events.notifyListeners(
                            CalendarDataSourceAction.add, [eventData]);
                      } catch (e, stackTrace) {
                        log(e.toString(), error: e, stackTrace: stackTrace);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Gagal menambahkan acara, silahkan coba lagi!"),
                          ),
                        );
                      }
                    },
                    onDeleted: () {
                      _events.appointments.removeWhere((element) =>
                          element['id'] ==
                          calendarTapDetails.appointments!.first['id']);
                      _events.notifyListeners(CalendarDataSourceAction.remove,
                          [calendarTapDetails.appointments!.first]);
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
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
          onEventAdded: (eventData) async {
            try {
              _events.appointments.add(eventData);
              _events
                  .notifyListeners(CalendarDataSourceAction.add, [eventData]);
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

class _EventDataSource extends CalendarDataSource<Map<String, dynamic>> {
  _EventDataSource({
    required this.source,
  });

  final List<Map<String, dynamic>> source;

  @override
  List<Map<String, dynamic>> get appointments => source;

  @override
  Object? getId(int index) {
    return appointments[index]['id'];
  }

  @override
  String getSubject(int index) {
    final isDone =
        Hive.box('acaraSelesaiBox').get(appointments[index]['id']) != null;
    final subject = appointments[index]['judul'];

    if (isDone) {
      return '$subject [Selesai]';
    }

    return subject;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments[index]['tanggal_mulai'] as Timestamp).toDate();
  }

  @override
  DateTime getEndTime(int index) {
    if (appointments[index]['tanggal_selesai'] != null) {
      return (appointments[index]['tanggal_selesai'] as Timestamp).toDate();
    }
    return getStartTime(index);
  }

  @override
  String? getNotes(int index) {
    return appointments[index]['deskripsi'];
  }

  @override
  Color getColor(int index) {
    return Color(appointments[index]['warna']);
  }

  @override
  bool isAllDay(int index) {
    return appointments[index]['seharian'] ||
        appointments[index]['tanggal_selesai'] == null;
  }

  @override
  Object? getRecurrenceId(int index) {
    if (appointments[index]['ulangi'] == 'none' ||
        appointments[index]['ulangi'] == null) {
      return null;
    }
    return appointments[index]['id'];
  }

  @override
  String? getRecurrenceRule(int index) {
    if (appointments[index]['ulangi'] == 'none' ||
        appointments[index]['ulangi'] == null) {
      return null;
    }
    final properties = RecurrenceProperties(startDate: getStartTime(index));
    final rRule = SfCalendar.generateRRule(
      switch (appointments[index]['ulangi']) {
        'harian' => properties..recurrenceType = RecurrenceType.daily,
        'mingguan' => properties
          ..recurrenceType = RecurrenceType.weekly
          ..weekDays = _generateWeekdays(getStartTime(index)),
        'bulanan' => properties..recurrenceType = RecurrenceType.monthly,
        'tahunan' => properties..recurrenceType = RecurrenceType.yearly,
        _ => throw Exception(
            'Invalid recurrence type: ${appointments[index]['ulangi']}'),
      },
      getStartTime(index),
      getEndTime(index),
    );
    print(rRule);
    return rRule;
    // return super.getRecurrenceRule(index);
  }

  List<WeekDays> _generateWeekdays(DateTime start) {
    final weekdays = <WeekDays>[];
    if (start.weekday == DateTime.monday) {
      weekdays.add(WeekDays.monday);
    } else if (start.weekday == DateTime.tuesday) {
      weekdays.add(WeekDays.tuesday);
    } else if (start.weekday == DateTime.wednesday) {
      weekdays.add(WeekDays.wednesday);
    } else if (start.weekday == DateTime.thursday) {
      weekdays.add(WeekDays.thursday);
    } else if (start.weekday == DateTime.friday) {
      weekdays.add(WeekDays.friday);
    } else if (start.weekday == DateTime.saturday) {
      weekdays.add(WeekDays.saturday);
    } else if (start.weekday == DateTime.sunday) {
      weekdays.add(WeekDays.sunday);
    }
    return weekdays;
  }

  @override
  Map<String, dynamic> convertAppointmentToObject(
    Map<String, dynamic> customData,
    Appointment appointment,
  ) {
    return customData;
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

      if (kelasIds.isEmpty) {
        appointments.addAll(meetings);
        notifyListeners(CalendarDataSourceAction.add, meetings);
        return;
      }

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
