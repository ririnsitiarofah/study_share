import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:studyshare/core/utils/notifications_utils.dart';
import 'package:studyshare/views/core/utils/colors.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({
    super.key,
    this.initialAppointmentData,
    this.initialDate,
    this.initialIdKelas,
    this.changable = true,
    required this.initialType,
    this.onEventAdded,
    this.onEventUpdated,
  });

  final Map<String, dynamic>? initialAppointmentData;
  final DateTime? initialDate;
  final String? initialIdKelas;
  final bool changable;
  final String initialType;
  final void Function(Map<String, dynamic> eventData)? onEventAdded;
  final void Function(Map<String, dynamic> eventData)? onEventUpdated;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  late Appointment _selectedAppointment;

  Map<String, dynamic>? _selectedKelas;

  late final Map<String, String> _eventTypes;
  late var _selectedEventType = _eventTypes.keys.first;

  final _getKelas = FirebaseFirestore.instance
      .collection('member_kelas')
      .where(
        'id_user',
        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
      )
      .get();

  @override
  void initState() {
    _eventTypes = {
      'acara': 'Acara',
      'tugas': 'Tugas',
    }..removeWhere((key, value) {
        return !widget.changable && key != widget.initialType;
      });

    if (widget.initialAppointmentData == null) {
      final date = widget.initialDate!;
      final now = DateTime.now();
      final DateTime newDate;
      if (date.hour == 0 && date.minute == 0) {
        newDate = DateTime(
          date.year,
          date.month,
          date.day,
          now.hour,
        );
      } else {
        newDate = date;
      }
      _selectedAppointment = Appointment(
        startTime: newDate,
        endTime: newDate.add(const Duration(minutes: 40)),
        color: Color(colorPalettes.first.color),
      );
    } else {
      final event = widget.initialAppointmentData!;
      final id = event['id'];
      final startTime = (event['tanggal_mulai'] as Timestamp).toDate();
      final endTime = event['tanggal_selesai'] != null
          ? (event['tanggal_selesai'] as Timestamp).toDate()
          : startTime.add(const Duration(hours: 1));
      final notes = event['deskripsi'];
      final properties = RecurrenceProperties(startDate: startTime);
      final recurrenceRule = event['ulangi'] == 'none' ||
              event['ulangi'] == null
          ? null
          : SfCalendar.generateRRule(
              switch (event['ulangi']) {
                'harian' => properties..recurrenceType = RecurrenceType.daily,
                'mingguan' => properties
                  ..recurrenceType = RecurrenceType.weekly
                  ..weekDays = [
                    WeekDays.friday,
                  ],
                'bulanan' => properties
                  ..recurrenceType = RecurrenceType.monthly,
                'tahunan' => properties..recurrenceType = RecurrenceType.yearly,
                _ => throw Exception(
                    'Invalid recurrence type: ${event['ulangi']}'),
              },
              startTime,
              endTime,
            );
      final subject = event['judul'];
      final color = Color(event['warna']);
      final isAllDay = event['seharian'] ||
          (event['tipe'] == 'acara' && event['tanggal_selesai'] == null);

      _selectedAppointment = Appointment(
        id: id,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
        recurrenceRule: recurrenceRule,
        subject: subject,
        color: color,
        isAllDay: isAllDay,
      );
    }
    _selectedEventType = widget.initialType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          FilledButton(
            onPressed: () async {
              if (_selectedKelas == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pilih kelas terlebih dahulu'),
                  ),
                );
                return;
              }
              if (_selectedAppointment.subject.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Judul tidak boleh kosong'),
                  ),
                );
                return;
              }

              if (widget.initialAppointmentData != null) {
                await _updateEvent();
              } else {
                await _addEvent();
              }

              await saveNotifications(context);
            },
            child: const Text('Simpan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          TextFormField(
            initialValue: _selectedAppointment.subject,
            style: textTheme.headlineSmall,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.words,
            maxLines: null,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 48),
              hintText: 'Tambahkan judul',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _selectedAppointment.subject = value;
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _eventTypes.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedEventType == entry.key,
                  onSelected: (selected) {
                    setState(() {
                      _selectedEventType = entry.key;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(),
          FutureBuilder(
            future: _getKelas,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ListTile(
                  title: Text('Memuat kelas...'),
                  leading: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return ListTile(
                  title: const Text('Gagal memuat kelas'),
                  leading: const Icon(Icons.error),
                  subtitle: Text(snapshot.error.toString()),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return const ListTile(
                  title: Text('Tidak ada kelas'),
                  leading: Icon(Icons.error),
                );
              }

              final docs = snapshot.data!.docs;

              if (widget.initialAppointmentData != null) {
                final idKelas = widget.initialAppointmentData!['id_kelas'];

                _selectedKelas ??= {
                  'id': idKelas,
                  ...docs
                      .firstWhere((doc) => doc.data()['id_kelas'] == idKelas)
                      .data(),
                };
              } else if (widget.initialIdKelas != null) {
                _selectedKelas ??= {
                  'id': widget.initialIdKelas,
                  ...docs
                      .firstWhere((doc) =>
                          doc.data()['id_kelas'] == widget.initialIdKelas)
                      .data(),
                };
              } else {
                _selectedKelas ??= {
                  'id': docs.first['id_kelas'],
                  ...docs.first.data(),
                };
              }

              return ListTile(
                title: Text(_selectedKelas!['nama_kelas']),
                leading: const Icon(Icons.class_),
                trailing: const Icon(Icons.arrow_drop_down),
                enabled: widget.changable,
                onTap: () async {
                  final kelas = await showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: const Text('Pilih kelas'),
                        children: docs.map((doc) {
                          return RadioListTile<String>(
                            title: Text(doc.data()['nama_kelas']),
                            value: doc['id_kelas'],
                            groupValue: _selectedKelas!['id'],
                            onChanged: (value) {
                              Navigator.pop(
                                context,
                                {'id': value, ...doc.data()},
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                  setState(() {
                    _selectedKelas = kelas;
                  });
                },
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextFormField(
              initialValue: _selectedAppointment.notes,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes),
                hintText: 'Tambahkan deskripsi',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _selectedAppointment.notes = value;
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Seharian'),
            secondary: const Icon(Icons.schedule),
            value: _selectedAppointment.isAllDay,
            onChanged: (value) {
              setState(() {
                _selectedAppointment.isAllDay = value;
              });
            },
          ),
          ListTile(
            title: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _selectedAppointment.startTime,
                );

                if (date == null) return;

                setState(() {
                  _selectedAppointment.startTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    _selectedAppointment.startTime.hour,
                    _selectedAppointment.startTime.minute,
                  );
                  if (_selectedAppointment.startTime
                      .isAfter(_selectedAppointment.endTime)) {
                    _selectedAppointment.endTime = _selectedAppointment
                        .startTime
                        .add(const Duration(hours: 1));
                  }
                });
              },
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatDate(_selectedAppointment.startTime),
                    style: textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            leading: const SizedBox(),
            trailing: _selectedAppointment.isAllDay
                ? null
                : InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            _selectedAppointment.startTime),
                      );
                      if (time == null) return;

                      setState(() {
                        _selectedAppointment.startTime = DateTime(
                          _selectedAppointment.startTime.year,
                          _selectedAppointment.startTime.month,
                          _selectedAppointment.startTime.day,
                          time.hour,
                          time.minute,
                        );
                        if (_selectedAppointment.startTime
                            .isAfter(_selectedAppointment.endTime)) {
                          _selectedAppointment.endTime = _selectedAppointment
                              .startTime
                              .add(const Duration(hours: 1));
                        }
                      });
                    },
                    child: SizedBox(
                      height: 48,
                      width: 52,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatTime(_selectedAppointment.startTime),
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_selectedEventType == 'acara')
            ListTile(
              title: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: _selectedAppointment.endTime,
                  );

                  if (date != null) {
                    setState(() {
                      _selectedAppointment.endTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        _selectedAppointment.endTime.hour,
                        _selectedAppointment.endTime.minute,
                      );
                      if (_selectedAppointment.endTime
                          .isBefore(_selectedAppointment.startTime)) {
                        _selectedAppointment.startTime = _selectedAppointment
                            .endTime
                            .subtract(const Duration(hours: 1));
                      }
                    });
                  }
                },
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatDate(_selectedAppointment.endTime),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
              leading: const SizedBox(),
              trailing: _selectedAppointment.isAllDay
                  ? null
                  : InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _selectedAppointment.endTime),
                        );
                        if (time == null) return;

                        setState(() {
                          _selectedAppointment.endTime = DateTime(
                            _selectedAppointment.endTime.year,
                            _selectedAppointment.endTime.month,
                            _selectedAppointment.endTime.day,
                            time.hour,
                            time.minute,
                          );
                          if (_selectedAppointment.endTime
                              .isBefore(_selectedAppointment.startTime)) {
                            _selectedAppointment.startTime =
                                _selectedAppointment.endTime
                                    .subtract(const Duration(hours: 1));
                          }
                        });
                      },
                      child: SizedBox(
                        height: 48,
                        width: 52,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatTime(_selectedAppointment.endTime),
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
            ),
          ListTile(
            title: Text(_selectedAppointment.recurrenceRule == null
                ? 'Tidak berulang'
                : switch (SfCalendar.parseRRule(
                        _selectedAppointment.recurrenceRule!,
                        _selectedAppointment.startTime)
                    .recurrenceType) {
                    RecurrenceType.daily => 'Setiap hari',
                    RecurrenceType.weekly => 'Setiap pekan',
                    RecurrenceType.monthly => 'Setiap bulan',
                    RecurrenceType.yearly => 'Setiap tahun',
                  }),
            leading: const Icon(Icons.replay),
            onTap: () async {
              final recurrence = SfCalendar.parseRRule(
                _selectedAppointment.recurrenceRule ?? '',
                _selectedAppointment.startTime,
              );

              final recurrenceType = _selectedAppointment.recurrenceRule == null
                  ? 'none'
                  : recurrence.recurrenceType;

              final result = await showDialog<Object?>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Berulang'),
                    children: [
                      RadioListTile(
                        title: const Text('Tidak berulang'),
                        value: 'none',
                        groupValue: recurrenceType,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                        },
                      ),
                      RadioListTile(
                        title: const Text('Setiap hari'),
                        value: RecurrenceType.daily,
                        groupValue: recurrenceType,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                        },
                      ),
                      RadioListTile(
                        title: const Text('Setiap pekan'),
                        value: RecurrenceType.weekly,
                        groupValue: recurrenceType,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                        },
                      ),
                      RadioListTile(
                        title: const Text('Setiap bulan'),
                        value: RecurrenceType.monthly,
                        groupValue: recurrenceType,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                        },
                      ),
                      RadioListTile(
                        title: const Text('Setiap tahun'),
                        value: RecurrenceType.yearly,
                        groupValue: recurrenceType,
                        onChanged: (value) {
                          Navigator.pop(context, value);
                        },
                      ),
                    ],
                  );
                },
              );

              if (result == null) return;

              if (result == 'none') {
                setState(() {
                  _selectedAppointment.recurrenceRule = null;
                });
                return;
              }

              recurrence.recurrenceType = result as RecurrenceType;

              setState(() {
                _selectedAppointment.recurrenceRule = SfCalendar.generateRRule(
                  recurrence,
                  _selectedAppointment.startTime,
                  _selectedAppointment.endTime,
                );
              });
            },
          ),
          const Divider(),
          ListTile(
            title: Text(colorPalettes
                .firstWhere(
                  (palette) =>
                      palette.color == _selectedAppointment.color.value,
                  orElse: () => colorPalettes.first,
                )
                .name),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _selectedAppointment.color,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () async {
              final color = await showDialog<int>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Pilih warna'),
                    children: colorPalettes
                        .map(
                          (palette) => ListTile(
                            title: Text(palette.name),
                            visualDensity: VisualDensity.compact,
                            leading: Container(
                              margin: const EdgeInsets.all(8),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(palette.color),
                                shape: BoxShape.circle,
                              ),
                              child: _selectedAppointment.color.value ==
                                      palette.color
                                  ? Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            onTap: () {
                              Navigator.pop(context, palette.color);
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              );

              if (color == null) return;

              setState(() {
                _selectedAppointment.color = Color(color);
              });
            },
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat.Hm().format(date);
  }

  Future<void> _addEvent() async {
    try {
      context.loaderOverlay.show();

      final user = FirebaseAuth.instance.currentUser!;
      final eventMap = _generateEventMap(user);

      final doc =
          await FirebaseFirestore.instance.collection('acara').add(eventMap);

      Navigator.pop(context);

      widget.onEventAdded?.call({
        'id': doc.id,
        ...eventMap,
      });
    } catch (e, stackTrace) {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menambahkan acara, silahkan coba lagi!"),
        ),
      );
    } finally {
      context.loaderOverlay.hide();
    }
  }

  Future<void> _updateEvent() async {
    try {
      context.loaderOverlay.show();

      final user = FirebaseAuth.instance.currentUser!;
      final eventMap = _generateEventMap(user)..remove('tanggal_dibuat');

      await FirebaseFirestore.instance
          .collection('acara')
          .doc(widget.initialAppointmentData!['id'])
          .update(eventMap);

      Navigator.pop(context);

      widget.onEventUpdated?.call({
        'id': widget.initialAppointmentData!['id'],
        ...eventMap,
      });
    } catch (e, stackTrace) {
      log(e.toString(), error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menambahkan acara, silahkan coba lagi!"),
        ),
      );
    } finally {
      context.loaderOverlay.hide();
    }
  }

  Map<String, dynamic> _generateEventMap(User user) {
    return {
      'id_pemilik': user.uid,
      'id_kelas': _selectedKelas!['id'],
      'judul': _selectedAppointment.subject,
      'nama_pemilik': user.displayName,
      'tanggal_mulai': Timestamp.fromDate(_selectedAppointment.startTime),
      'tanggal_selesai': _selectedEventType == 'acara'
          ? Timestamp.fromDate(_selectedAppointment.endTime)
          : null,
      'ulangi': _selectedAppointment.recurrenceRule == null
          ? 'none'
          : switch (SfCalendar.parseRRule(_selectedAppointment.recurrenceRule!,
                  _selectedAppointment.startTime)
              .recurrenceType) {
              RecurrenceType.daily => 'harian',
              RecurrenceType.weekly => 'mingguan',
              RecurrenceType.monthly => 'bulanan',
              RecurrenceType.yearly => 'tahunan',
            },
      'seharian': _selectedAppointment.isAllDay,
      'tipe': _selectedEventType,
      'warna': _selectedAppointment.color.value,
      'deskripsi': _selectedAppointment.notes,
      'terakhir_diubah': Timestamp.now(),
      'tanggal_dibuat': Timestamp.now(),
    };
  }
}
