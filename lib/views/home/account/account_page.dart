import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/auth/reset_password_page.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
import 'package:studyshare/views/home/account/update_email_page.dart';
import 'package:studyshare/views/home/setting/setting_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text("Akun"),
              backgroundColor: colorScheme.background,
              actions: [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text("Pengaturan"),
                    ),
                    const PopupMenuItem(
                      value: 'sign_out',
                      child: Text("Keluar"),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'settings':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingPage(),
                          ),
                        );
                        break;
                      case 'sign_out':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            icon: const Icon(Icons.logout),
                            title: const Text("Keluar akun"),
                            content: const Text(
                              "Apakah kamu yakin ingin keluar akun?",
                            ),
                            actions: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Batal"),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                ),
                                onPressed: () {
                                  FirebaseAuth.instance.signOut();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignInPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text("Keluar"),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Profil Kamu",
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Semua orang di kelas kamu bakal bisa melihat info ini.",
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            const Divider(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text("Nama"),
                        subtitle: Text(user.displayName!),
                      ),
                      ListTile(
                        title: const Text("Email"),
                        subtitle: Text(user.email ?? "Belum diatur"),
                        trailing: const Icon(Icons.arrow_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UpdateEmailPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Password'),
                        subtitle: const Text('********'),
                        trailing: const Icon(Icons.arrow_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPasswordPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
