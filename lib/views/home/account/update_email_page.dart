import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';

class UpdateEmailPage extends StatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text("Ubah Email"),
              backgroundColor: colorScheme.background,
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masukkan email baru kamu, nanti bakal dikirimin link buat verifikasi emailnya.',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: "Emailnya gak boleh dikosongin yah.",
                            ),
                            FormBuilderValidators.email(
                              errorText: "Email kamu enggak valid eyyy.",
                            ),
                          ],
                        ),
                        decoration: const InputDecoration(
                          labelText: "Email Baru",
                          icon: Icon(Icons.mail_lock_rounded),
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
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            try {
                              await FirebaseAuth.instance.currentUser!
                                  .verifyBeforeUpdateEmail(
                                      _emailController.text);

                              await FirebaseAuth.instance.signOut();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Email verifikasi udah berhasil dikirim. Habis verifikasi, silahkan login lagi yah."),
                                ),
                              );

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                                (route) => false,
                              );
                            } catch (e, stackTrace) {
                              log(e.toString(),
                                  error: e, stackTrace: stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Gagal mengirim email reset password."),
                                ),
                              );
                            }
                          },
                          child: const Text('Kirim'),
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
