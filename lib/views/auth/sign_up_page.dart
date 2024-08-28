import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text("Buat akun sekarang!"),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat akunnya gampang banget, kamu cuman perlu masukin data di bawah, langsung cuss bisa nikmatin semua fitur di StudyShare!',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        autocorrect: false,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: "Namanya gak boleh dikosongin yah.",
                            ),
                          ],
                        ),
                        decoration: const InputDecoration(
                          labelText: "Nama Lengkap",
                          icon: Icon(Icons.person_2_rounded),
                        ),
                      ),
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
                              errorText: 'Emailnya kamu enggak valid.',
                            ),
                          ],
                        ),
                        decoration: const InputDecoration(
                          labelText: "Email",
                          icon: Icon(Icons.email_rounded),
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText:
                                  "Passwordnya gak boleh dikosongin yah.",
                            ),
                            FormBuilderValidators.minLength(
                              8,
                              errorText: "Passwornya minimal 8 karakter yah.",
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          icon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(_showPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                      ),
                      TextFormField(
                        obscureText: !_showPassword,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: "Passwordnya gak sama.",
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          icon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(_showPassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
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
                            try {
                              final cred = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                      email: _emailController.text,
                                      password: _passwordController.text);

                              await cred.user!
                                  .updateDisplayName(_nameController.text);

                              await FirebaseFirestore.instance
                                  .collection('user')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .set({
                                'nama': _nameController.text,
                              });

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            } catch (e, stackTrace) {
                              log(e.toString(),
                                  error: e, stackTrace: stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Emailnya udah pernah dipake"),
                                ),
                              );
                            }
                          },
                          child: const Text('Buat Akun'),
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
                                    builder: (context) => const SignInPage()));
                          },
                          child: const Text('Aku sudah punya akun'),
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
