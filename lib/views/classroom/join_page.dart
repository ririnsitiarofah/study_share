import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/classroom/create_classroom.dart';
import 'package:studyshare/views/classroom/scan_page.dart';
import 'package:studyshare/views/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class JoinPage extends StatelessWidget {
  const JoinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text("Ayo join!"),
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
                        'Masukin kode kelas kamu di bawah (psst, tanyain kodenya ke temen kamu)',
                      ),
                      TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.minLength(
                              16,
                              errorText: "Kode kelas kamu enggak valid eyyy.",
                            ),
                          ],
                        ),
                        decoration: const InputDecoration(
                          labelText: "Kode Kelas",
                          icon: Icon(Icons.pin_rounded),
                        ),
                      ),
                      TextFormField(
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: 'NIM kamu gak boleh kosong yah.',
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          labelText: 'NIM (Nomor Indu Mahasiswa)',
                          icon: const Icon(Icons.badge_rounded),
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
                          child: const Text('Join Kelas'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        CreateClassroomPage()));
                          },
                          child: const Text('Buat Kelas'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.center,
                        child: Text('Kamu males ngetik?'),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: colorScheme.onPrimary,
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: Theme.of(context).textTheme.headline6,
                          ).copyWith(
                            elevation: ButtonStyleButton.allOrNull(0),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ScanPage()));
                          },
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 28,
                          ),
                          label: const Text('Scan QR'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Salah akun?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignInPage()));
                            },
                            child: const Text('Masuk lagi'),
                          ),
                        ],
                      )
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
