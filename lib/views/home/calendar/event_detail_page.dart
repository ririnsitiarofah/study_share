import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({
    super.key,
    required this.idTugas,
    this.onDeleted,
  });

  final String idTugas;
  final void Function()? onDeleted;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _getEvent;

  @override
  void initState() {
    _getEvent = FirebaseFirestore.instance
        .collection('acara')
        .doc(widget.idTugas)
        .get();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
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

          final data = snapshot.data!.data()!;

          return ListView(
            children: [
              ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(data['warna']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['judul'],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      _formatRangeDate(data['tanggal_mulai'], null),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (data['deskripsi'] != null)
                ListTile(
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.notes),
                  ),
                  titleAlignment: ListTileTitleAlignment.top,
                  title: Text(data['deskripsi']),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Dibuat oleh'),
                subtitle: Text(data['nama_pemilik']),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Dibuat pada'),
                subtitle: Text(_formatDate(data['tanggal_dibuat'])),
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
            TextButton(
              onPressed: () {},
              child: const Text('Tandai selesai'),
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
}
