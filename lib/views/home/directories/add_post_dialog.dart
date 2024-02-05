import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddPostDialog extends StatefulWidget {
  const AddPostDialog({
    super.key,
    this.existingPostId,
    this.existingPostTitle,
    this.existingPostDesc,
    required this.idKelas,
    required this.idParent,
  });
  final String? idParent;
  final String? idKelas;

  final String? existingPostId;
  final String? existingPostTitle;
  final String? existingPostDesc;

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _selectedFiles = <PlatformFile>[];

  var _isDragging = false;

  @override
  void initState() {
    if (widget.existingPostId != null) {
      _titleController.text = widget.existingPostTitle!;
      _descriptionController.text = widget.existingPostDesc ?? '';
    }
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPostId == null ? 'Buat post' : 'Edit post'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (widget.existingPostId != null) {
                return;
              }
              try {
                if (!_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Isi semua kolom'),
                    ),
                  );
                  return;
                }
                final ref = FirebaseStorage.instance.ref('berkas_kelas');
                final lampirans = <String, dynamic>{};

                for (final file in _selectedFiles) {
                  final id = const Uuid().v4();
                  final result = await ref
                      .child('$id.${file.extension!}')
                      .putFile(File(file.path!),
                          SettableMetadata(contentType: file.extension));
                  final url = await result.ref.getDownloadURL();

                  lampirans[id] = {
                    'nama': file.name,
                    'url': url,
                    'type': file.extension,
                    'size': file.size,
                  };
                }

                final user = FirebaseAuth.instance.currentUser!;

                await FirebaseFirestore.instance.collection('direktori').add(
                  {
                    'id_parent': widget.idParent,
                    'id_pemilik': user.uid,
                    'id_kelas': widget.idKelas,
                    'nama': _titleController.text,
                    'deskripsi': _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    'warna': null,
                    'tipe': 'postingan',
                    'lampiran': lampirans,
                    'tanggal_dibuat': FieldValue.serverTimestamp(),
                    'terakhir_dimodifikasi': FieldValue.serverTimestamp(),
                  },
                );
                Navigator.pop(context);
              } catch (e, stackTrace) {
                log(e.toString(), error: e, stackTrace: stackTrace);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menyimpan folder"),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.title),
                        label: Text('Judul Postingan'),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.notes),
                        label: Text('Deskripsi'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.existingPostId == null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Pilih berkas',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 180,
                        ),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          border: Border.all(
                            color: _isDragging
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            width: _isDragging ? 2 : 1,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.any,
                                  );
                                  if (result == null) return;

                                  setState(() {
                                    _selectedFiles.clear();
                                    _selectedFiles.addAll(result.files);
                                  });
                                } catch (e, stackTrace) {
                                  log(e.toString(),
                                      error: e, stackTrace: stackTrace);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Gagal memilih file, coba lagi nanti"),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Pilih FIle"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Berkas yang dipilih',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];

                  return ListTile(
                    title: Text(file.name),
                    leading: CircleAvatar(
                      child: _isImage(file.extension)
                          ? Image.file(
                              File(file.path!),
                            )
                          : const Icon(Icons.insert_drive_file),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFiles.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isImage(String? extension) {
    return extension == 'jpg' || extension == 'png' || extension == 'jpeg';
  }
}
