import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SfCalendar(
          controller: _calendarController,
          dataSource: _events,
          appointmentBuilder: (context, calendarAppointmentDetails) {
            final event = calendarAppointmentDetails.appointments.first;
            final brightness =
                ThemeData.estimateBrightnessForColor(Color(event['warna']));

            return ValueListenableBuilder(
              valueListenable: Hive.box('acaraSelesaiBox').listenable(),
              builder: (context, value, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(event['warna']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              if (value.containsKey(event['id'])) ...[
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: brightness == Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  event['judul'],
                                  style: (event['tipe'] == 'acara'
                                          ? textTheme.bodyMedium
                                          : textTheme.bodySmall)
                                      ?.copyWith(
                                    color: brightness == Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (event['tipe'] == 'acara' && !event['seharian'])
                          Text(
                            _formatRangeDate(event['tanggal_mulai'], null),
                            style: textTheme.bodySmall?.copyWith(
                              color: brightness == Brightness.light
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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

  String _formatRangeDate(Timestamp startDate, Timestamp? endDate) {
    if (endDate == null) {
      return DateFormat('HH:mm').format(startDate.toDate());
    } else if (startDate.toDate().day == endDate.toDate().day) {
      return DateFormat('HH:mm -').format(startDate.toDate()).replaceFirst(
          '-', '- ${DateFormat('HH:mm').format(endDate.toDate())}');
    } else {
      return DateFormat('HH:mm -').format(startDate.toDate()).replaceFirst(
          '-', '- ${DateFormat('HH:mm').format(endDate.toDate())}');
    }
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
    if (appointments[index]['tanggal_selesai'] != null) {
      return (appointments[index]['tanggal_selesai'] as Timestamp).toDate();
    }
    return getStartTime(index).add(const Duration(hours: 1));
  }

  @override
  String? getNotes(int index) {
    return appointments[index]['deskripsi'];
  }

  @override
  Object? getRecurrenceId(int index) {
    return appointments[index]['id'];
  }

  @override
  String? getRecurrenceRule(int index) {
    // if (appointments[index]['ulangi'] != 'none') {
    //   final properties = RecurrenceProperties(startDate: getStartTime(index));
    //   return SfCalendar.generateRRule(
    //     switch (appointments[index]['ulangi']) {
    //       'harian' => properties..recurrenceType = RecurrenceType.daily,
    //       'mingguan' => properties..recurrenceType = RecurrenceType.weekly,
    //       'bulanan' => properties..recurrenceType = RecurrenceType.monthly,
    //       'tahunan' => properties..recurrenceType = RecurrenceType.yearly,
    //       _ => throw Exception(
    //           'Invalid recurrence type: ${appointments[index]['ulangi']}'),
    //     },
    //     getStartTime(index),
    //     getEndTime(index),
    //   );
    // }
    // return super.getRecurrenceRule(index);
    return null;
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
    return appointments[index]['seharian'] ||
        appointments[index]['tanggal_selesai'] == null;
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
