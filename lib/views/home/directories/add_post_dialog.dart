import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final _selectedFiles = <String>[];

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
            onPressed: () {
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
                final user = FirebaseAuth.instance.currentUser!;

                FirebaseFirestore.instance.collection('direktori').add(
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
                    'lampiran': [],
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
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Pilih berkas',
                  style: textTheme.titleMedium,
                ),
              ),
              Container(
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
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Pilih FIle"),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
