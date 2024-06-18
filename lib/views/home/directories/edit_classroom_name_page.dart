import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditClassroomNamePage extends StatefulWidget {
  const EditClassroomNamePage({
    super.key,
    required this.idKelas,
    required this.namaKelas,
  });

  final String idKelas;
  final String namaKelas;

  @override
  State<EditClassroomNamePage> createState() => _EditClassroomNamePageState();
}

class _EditClassroomNamePageState extends State<EditClassroomNamePage> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.namaKelas);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Nama Kelas'),
        actions: [
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await FirebaseFirestore.instance
                    .collection('kelas')
                    .doc(widget.idKelas)
                    .update({'nama': _nameController.text});

                final snapshot = await FirebaseFirestore.instance
                    .collection('member_kelas')
                    .where('id_kelas', isEqualTo: widget.idKelas)
                    .get();

                final batch = FirebaseFirestore.instance.batch();
                final docs = snapshot.docs;
                final ref =
                    FirebaseFirestore.instance.collection('member_kelas');
                for (var i = 0; i < docs.length; i++) {
                  batch.update(ref.doc(docs[i].id), {
                    'nama_kelas': _nameController.text,
                  });
                }
                await batch.commit();
                Navigator.pop(context, _nameController.text);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama kelas tidak boleh kosong';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'Masukkan Nama Kelas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
