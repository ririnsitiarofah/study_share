import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/home/calendar/event_detail_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.idKelas});

  final String idKelas;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final Query<Map<String, dynamic>> _query;

  @override
  void initState() {
    _query = FirebaseFirestore.instance
        .collection('acara')
        .where('id_kelas', isEqualTo: widget.idKelas)
        .where('tipe', isEqualTo: 'tugas');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tasks = <Map<String, dynamic>>[];

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        const SliverAppBar.large(
          title: Text('Tugas'),
        ),
      ],
      body: FirestoreListView(
        query: _query,
        padding: EdgeInsets.zero,
        emptyBuilder: (context) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment, size: 64),
                SizedBox(height: 8),
                Text('Tidak ada tugas'),
              ],
            ),
          );
        },
        itemBuilder: (context, doc) {
          final isFirst = tasks.isEmpty;
          final isDifferentDate = isFirst ||
              _formatDate(tasks.last['tanggal_mulai']) !=
                  _formatDate(doc['tanggal_mulai']);

          tasks.add(doc.data());

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDifferentDate)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    _formatDate(doc['tanggal_mulai']),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(doc['judul']),
                  subtitle: Text(
                    doc['deskripsi'] ?? 'Tidak ada deskripsi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  leading: SizedBox(
                    width: 24,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(doc['warna']),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  trailing: SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(_formatTime(doc['tanggal_mulai'])),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailPage(
                        idTugas: doc.id,
                      ),
                      fullscreenDialog: true,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp date) {
    return DateFormat.yMMMMd().format(date.toDate());
  }

  String _formatTime(Timestamp date) {
    return DateFormat.Hm().format(date.toDate());
  }
}
