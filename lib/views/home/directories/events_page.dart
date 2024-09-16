import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/home/calendar/event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.idKelas});

  final String idKelas;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final Query<Map<String, dynamic>> _queryMendatang;
  late final Query<Map<String, dynamic>> _queryYangLalu;

  @override
  void initState() {
    _queryMendatang = FirebaseFirestore.instance
        .collection('acara')
        .where('id_kelas', isEqualTo: widget.idKelas)
        .where('tipe', isEqualTo: 'acara')
        .where('tanggal_mulai', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('tanggal_mulai');

    _queryYangLalu = FirebaseFirestore.instance
        .collection('acara')
        .where('id_kelas', isEqualTo: widget.idKelas)
        .where('tipe', isEqualTo: 'acara')
        .where('tanggal_mulai', isLessThan: Timestamp.now())
        .orderBy('tanggal_mulai', descending: true);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(
          title: Text('Acara'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "Mendatang",
              style: textTheme.titleSmall,
            ),
          ),
        ),
        FirestoreQueryBuilder(
          query: _queryMendatang,
          builder: (context, snapshot, child) {
            if (snapshot.isFetching) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Text('Something went wrong! ${snapshot.error}'),
                ),
              );
            }

            if (snapshot.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text("Tidak ada acara mendatang"),
                    ),
                  ],
                ),
              );
            }

            return SliverList.builder(
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                  snapshot.fetchMore();
                }

                final doc = snapshot.docs[index];

                return ValueListenableBuilder(
                  valueListenable: Hive.box('acaraSelesaiBox').listenable(),
                  builder: (context, value, child) {
                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                value.containsKey(doc.id)
                                    ? Icons.close
                                    : Icons.check,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                value.containsKey(doc.id)
                                    ? 'Batalkan selesai'
                                    : 'Tandai selesai',
                              ),
                            ],
                          ),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        try {
                          final box = await Hive.openBox('acaraSelesaiBox');

                          if (value.containsKey(doc.id)) {
                            await box.delete(doc.id);
                          } else {
                            await box.put(doc.id, true);
                          }
                          return false;
                        } catch (e, stackTrace) {
                          log(e.toString(), error: e, stackTrace: stackTrace);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Gagal menandai selesai. Silakan coba lagi."),
                            ),
                          );
                          return false;
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Flexible(child: Text(doc['judul'])),
                                  if (value.containsKey(doc.id))
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Selesai',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                _formatDate(doc['tanggal_mulai']) +
                                    ', ' +
                                    _formatRangeDate(doc['tanggal_mulai'],
                                        doc['tanggal_selesai']),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
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
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                    ),
                                  ),
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
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "Telah Berlalu",
              style: textTheme.titleSmall,
            ),
          ),
        ),
        FirestoreQueryBuilder(
          query: _queryYangLalu,
          builder: (context, snapshot, child) {
            if (snapshot.isFetching) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Text('Something went wrong! ${snapshot.error}'),
                ),
              );
            }

            if (snapshot.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text("Tidak ada acara yang lalu"),
                    ),
                  ],
                ),
              );
            }

            return SliverList.builder(
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                  snapshot.fetchMore();
                }

                final doc = snapshot.docs[index];

                return ValueListenableBuilder(
                  valueListenable: Hive.box('acaraSelesaiBox').listenable(),
                  builder: (context, value, child) {
                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                value.containsKey(doc.id)
                                    ? Icons.close
                                    : Icons.check,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                value.containsKey(doc.id)
                                    ? 'Batalkan selesai'
                                    : 'Tandai selesai',
                              ),
                            ],
                          ),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        try {
                          final box = await Hive.openBox('acaraSelesaiBox');

                          if (value.containsKey(doc.id)) {
                            await box.delete(doc.id);
                          } else {
                            await box.put(doc.id, true);
                          }
                          return false;
                        } catch (e, stackTrace) {
                          log(e.toString(), error: e, stackTrace: stackTrace);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Gagal menandai selesai. Silakan coba lagi."),
                            ),
                          );
                          return false;
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      doc['judul'],
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                  if (value.containsKey(doc.id))
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.outline,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Selesai',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                _formatDate(doc['tanggal_mulai']) +
                                    ', ' +
                                    _formatRangeDate(doc['tanggal_mulai'],
                                        doc['tanggal_selesai']),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
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
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                    ),
                                  ),
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
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(Timestamp date) {
    return DateFormat('d MMM yyyy').format(date.toDate());
  }

  String _formatRangeDate(Timestamp startDate, Timestamp? endDate) {
    if (endDate == null) {
      return DateFormat('HH:mm').format(startDate.toDate());
    } else if (startDate.toDate().day == endDate.toDate().day) {
      return DateFormat('HH:mm -').format(startDate.toDate()).replaceFirst(
          '-', '- ${DateFormat('HH:mm').format(endDate.toDate())}');
    } else {
      if (startDate.toDate().year == endDate.toDate().year) {
        return DateFormat('HH:mm').format(startDate.toDate()).replaceFirst(
            '-', '- ${DateFormat('d MMM, HH:mm').format(endDate.toDate())}');
      } else {
        return DateFormat('HH:mm').format(startDate.toDate()).replaceFirst('-',
            '- ${DateFormat('d MMM yyyy, HH:mm').format(endDate.toDate())}');
      }
    }
  }
}
