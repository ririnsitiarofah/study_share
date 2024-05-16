import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/home/calendar/add_event_page.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    required this.idTugas,
    this.onDeleted,
    this.onUpdated,
  });

  final String idTugas;
  final void Function()? onDeleted;
  final void Function(Map<String, dynamic> eventData)? onUpdated;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _getEvent;

  Map<String, dynamic>? _event;

  @override
  void initState() {
    _initialise();

    super.initState();
  }

  void _initialise() {
    _getEvent = FirebaseFirestore.instance
        .collection('acara')
        .doc(widget.idTugas)
        .get()
        .then((value) {
      _event = {
        'id': value.id,
        ...?value.data(),
      };
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEvent,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getEvent,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong! Error: ${snapshot.error}'),
            );
          }

          return ListView(
            children: [
              ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(_event!['warna']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _event!['judul'],
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable:
                              Hive.box('acaraSelesaiBox').listenable(),
                          builder: (context, value, child) {
                            if (!value.containsKey(widget.idTugas)) {
                              return const SizedBox();
                            }

                            return Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Selesai',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      _formatRangeDate(_event!['tanggal_mulai'], null),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (_event!['deskripsi'] != null)
                ListTile(
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.notes),
                  ),
                  titleAlignment: ListTileTitleAlignment.top,
                  title: Text(_event!['deskripsi']),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Dibuat oleh'),
                subtitle: Text(_event!['nama_pemilik']),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Dibuat pada'),
                subtitle: Text(_formatDate(_event!['tanggal_dibuat'])),
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text('Terakhir diubah'),
                subtitle: Text(_formatDate(_event!['terakhir_diubah'])),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ValueListenableBuilder(
              valueListenable: Hive.box('acaraSelesaiBox').listenable(),
              builder: (context, value, child) {
                return TextButton(
                  onPressed: () async {
                    try {
                      final box = await Hive.openBox('acaraSelesaiBox');

                      if (value.containsKey(widget.idTugas)) {
                        await box.delete(widget.idTugas);
                      } else {
                        await box.put(widget.idTugas, true);
                      }
                    } catch (e, stackTrace) {
                      log(e.toString(), error: e, stackTrace: stackTrace);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Gagal menandai selesai. Silakan coba lagi."),
                        ),
                      );
                    }
                  },
                  child: Text(value.containsKey(widget.idTugas)
                      ? 'Batalkan Selesai'
                      : 'Tandai Selesai'),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp date) =>
      DateFormat('EEEE, d MMM yyyy • HH:mm').format(date.toDate());

  String _formatRangeDate(Timestamp startDate, Timestamp? endDate) {
    if (endDate == null) {
      return DateFormat('EEEE, d MMM yyyy • HH:mm').format(startDate.toDate());
    } else if (startDate.toDate().day == endDate.toDate().day) {
      return DateFormat('EEEE, d MMM yyyy • HH:mm -')
          .format(startDate.toDate())
          .replaceFirst(
              '-', '- ${DateFormat('HH:mm').format(endDate.toDate())}');
    } else {
      return DateFormat('EEEE, d MMM yyyy, HH:mm -')
          .format(startDate.toDate())
          .replaceFirst('-',
              '- ${DateFormat('EEEE, d MMM yyyy, HH:mm').format(endDate.toDate())}');
    }
  }

  void _deleteEvent() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Tugas'),
          content: const Text('Apakah kamu yakin mau hapus tugas ini?'),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('acara')
                    .doc(widget.idTugas)
                    .delete();

                widget.onDeleted?.call();

                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _editEvent() {
    final event = _event!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddEventPage(
            initialType: event['tipe'],
            initialAppointmentData: event,
            onEventUpdated: (eventData) {
              setState(() {
                _initialise();
              });
              widget.onUpdated?.call(eventData);
            },
          );
        },
        fullscreenDialog: true,
      ),
    );
  }
}
