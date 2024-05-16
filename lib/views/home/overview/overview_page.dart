import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:studyshare/views/home/calendar/event_detail_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final _getKelasIds = () async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshotMember = await FirebaseFirestore.instance
        .collection('member_kelas')
        .where('id_user', isEqualTo: user.uid)
        .get();

    final kelasIds =
        snapshotMember.docs.map((e) => e.data()['id_kelas'] as String).toList();
    return kelasIds;
  }();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tasks = <Map<String, dynamic>>[];

    return Scaffold(
      body: FutureBuilder(
        future: _getKelasIds,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong! ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final kelasIds = snapshot.data as List<String>;

          return CustomScrollView(
            slivers: [
              const SliverAppBar.large(
                title: Text("Beranda"),
              ),
              FirestoreQueryBuilder(
                query: FirebaseFirestore.instance
                    .collection('acara')
                    .where('id_kelas', whereIn: kelasIds)
                    .where('tipe', isEqualTo: 'tugas')
                    .where(
                      'tanggal_mulai',
                      isGreaterThanOrEqualTo: DateTime.now(),
                    )
                    .where(
                      'tanggal_mulai',
                      isLessThanOrEqualTo:
                          DateTime.now().add(const Duration(days: 14)),
                    )
                    .orderBy('tanggal_mulai'),
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
                    return const SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Tidak ada tugas yang akan datang.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: snapshot.docs.length,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore &&
                          index + 1 == snapshot.docs.length) {
                        snapshot.fetchMore();
                      }

                      final doc = snapshot.docs[index];

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
                          ValueListenableBuilder(
                            valueListenable:
                                Hive.box('acaraSelesaiBox').listenable(),
                            builder: (context, value, child) {
                              return Dismissible(
                                key: ValueKey(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
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
                                    final box =
                                        await Hive.openBox('acaraSelesaiBox');

                                    if (value.containsKey(doc.id)) {
                                      await box.delete(doc.id);
                                    } else {
                                      await box.put(doc.id, true);
                                    }
                                    return false;
                                  } catch (e, stackTrace) {
                                    log(e.toString(),
                                        error: e, stackTrace: stackTrace);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Gagal menandai selesai. Silakan coba lagi."),
                                      ),
                                    );
                                    return false;
                                  }
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Flexible(child: Text(doc['judul'])),
                                        if (value.containsKey(doc.id))
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Selesai',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
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
                                                const BorderRadius.all(
                                                    Radius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    trailing: SizedBox(
                                      width: 36,
                                      child: Center(
                                        child: Text(
                                            _formatTime(doc['tanggal_mulai'])),
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
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              // SliverToBoxAdapter(
              //   child: Card(
              //     margin: const EdgeInsets.all(16),
              //     clipBehavior: Clip.antiAlias,
              //     child: Column(
              //       mainAxisSize: MainAxisSize.min,
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Padding(
              //           padding: const EdgeInsets.all(16),
              //           child: Row(
              //             children: [
              //               Icon(
              //                 Icons.task_alt,
              //                 color: colorScheme.primary,
              //               ),
              //               const SizedBox(width: 12),
              //               Text(
              //                 "Deadline Tugas",
              //                 style: textTheme.titleMedium,
              //               ),
              //             ],
              //           ),
              //         ),
              //         const Divider(indent: 8, endIndent: 8, height: 0),
              //         FirestoreListView(
              //           query: FirebaseFirestore.instance
              //               .collection('acara')
              //               .where('id_kelas', whereIn: kelasIds)
              //               .where('tipe', isEqualTo: 'tugas')
              //               .where(
              //                 'tanggal_mulai',
              //                 isGreaterThanOrEqualTo: DateTime.now(),
              //               )
              //               .where(
              //                 'tanggal_mulai',
              //                 isGreaterThanOrEqualTo:
              //                     DateTime.now().add(const Duration(days: 14)),
              //               )
              //               .orderBy('tanggal_mulai'),
              //           shrinkWrap: true,
              //           itemBuilder: (context, doc) {
              //             final isFirst = _tasks.isEmpty;
              //             final isDifferentDate = isFirst ||
              //                 _formatDate(_tasks.last['tanggal_mulai']) !=
              //                     _formatDate(doc['tanggal_mulai']);

              //             _tasks.add(doc.data());

              //             return Column(
              //               mainAxisSize: MainAxisSize.min,
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 if (isDifferentDate)
              //                   Padding(
              //                     padding:
              //                         const EdgeInsets.fromLTRB(16, 16, 16, 0),
              //                     child: Text(
              //                       _formatDate(doc['tanggal_mulai']),
              //                       style: textTheme.labelMedium?.copyWith(
              //                         color: colorScheme.primary,
              //                       ),
              //                     ),
              //                   ),
              //                 ListTile(
              //                   title: Text(doc['judul']),
              //                   isThreeLine: false,
              //                   subtitle: Column(
              //                     mainAxisSize: MainAxisSize.min,
              //                     crossAxisAlignment: CrossAxisAlignment.start,
              //                     children: [
              //                       Text(
              //                         doc['deskripsi'] ?? 'Tidak ada deskripsi',
              //                         maxLines: 1,
              //                         overflow: TextOverflow.ellipsis,
              //                         style: textTheme.bodyMedium?.copyWith(
              //                           color: colorScheme.inversePrimary,
              //                           fontStyle: FontStyle.italic,
              //                         ),
              //                       ),
              //                       Text(
              //                         _formatTime(doc['tanggal_mulai']),
              //                         style: textTheme.labelMedium?.copyWith(
              //                           color: colorScheme.outline,
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                   trailing: SizedBox(
              //                     width: 36,
              //                     child: Center(
              //                       child:
              //                           Text(_formatTime(doc['tanggal_mulai'])),
              //                     ),
              //                   ),
              //                 ),
              //               ],
              //             );
              //           },
              //         )
              //       ],
              //     ),
              //   ),
              // ),
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
