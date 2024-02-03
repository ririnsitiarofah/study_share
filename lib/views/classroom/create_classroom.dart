import 'package:studyshare/views/home/home_page.dart';

import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CreateClassroomPage extends StatelessWidget {
  const CreateClassroomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text("Ayo buat kelas!"),
              backgroundColor: colorScheme.background,
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              margin: EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Yuk buat kelas buat kamu sama temen kamu! Kalo bukan kamu siapa lagi, ya kan?",
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama kelas',
                          icon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.text,
                        validator: FormBuilderValidators.compose([]),
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi kelas',
                          icon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Sekalian lengkapin data kamu yuk!'),
                      const SizedBox(height: 24),
                      TextFormField(
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                            errorText: 'NIM kamu gak boleh kosong yah.',
                          ),
                        ]),
                        decoration: const InputDecoration(
                          labelText: 'NIM (Nomor Induk Mahasiswa)',
                          icon: Icon(Icons.badge_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            backgroundColor: colorScheme.primary,
                          ).copyWith(
                            elevation: ButtonStyleButton.allOrNull(0),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          },
                          child: const Text('Buat kelas'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
