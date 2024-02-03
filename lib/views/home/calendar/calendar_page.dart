import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendarControler = CalendarController();

  @override
  void dispose() {
    _calendarControler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AspectRatio(
          aspectRatio: 1,
          child: SfCalendar(
            controller: _calendarControler,
            view: CalendarView.month,
            showDatePickerButton: true,
            allowedViews: const [
              CalendarView.day,
              CalendarView.week,
              CalendarView.month,
              CalendarView.schedule,
            ],
          ),
        ),
      ),
    );
  }
}
