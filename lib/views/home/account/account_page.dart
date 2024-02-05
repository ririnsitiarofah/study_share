import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studyshare/views/auth/sign_in_page.dart';
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
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingPage()));
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Profil Kamu",
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Semua orang di kelas kamu bakal bisa melihat info ini.",
                          style: textTheme.bodyMedium,
                        ),
                        const Divider(
                          height: 8,
                        ),
                        ListTile(
                          title: const Text("Nama"),
                          subtitle: Text(user.displayName ?? "Belum diatur"),
                          trailing: const Icon(Icons.arrow_right),
                          onTap: () {},
                        ),
                        ListTile(
                          title: const Text("Email"),
                          subtitle: Text(user.email ?? "Belum diatur"),
                          trailing: const Icon(Icons.arrow_right),
                          onTap: () {},
                        ),
                        ListTile(
                          title: const Text('Password'),
                          subtitle: const Text('********'),
                          trailing: const Icon(Icons.arrow_right),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // SizedBox(
              //   width: double.infinity,
              //   child: Card(
              //     child: Padding(
              //       padding: const EdgeInsets.all(16),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             "Kelas",
              //             style: textTheme.titleMedium,
              //           ),
              //           const SizedBox(
              //             height: 8,
              //           ),
              //           Text(
              //             "Data kelas kamu sekarang",
              //             style: textTheme.bodyMedium,
              //           ),
              //           const Divider(
              //             height: 8,
              //           ),
              //           ListTile(
              //             title: const Text("Nama Kelas"),
              //             subtitle: const Text("PTIK 7 B"),
              //             trailing: const Icon(Icons.arrow_right),
              //             onTap: () {},
              //           ),
              //           ListTile(
              //             title: const Text("Kode Kelass"),
              //             subtitle: const Text("bgdgDahdGRDgd"),
              //             trailing: const Icon(Icons.qr_code),
              //             onTap: () {},
              //           ),
              //           ListTile(
              //             title: const Text('Anggota Kelas'),
              //             subtitle: const Text('22 anggota'),
              //             trailing: const Icon(Icons.arrow_right),
              //             onTap: () {},
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPage()),
                          (_) => false);
                    },
                    child: const Text('Keluar Akun'),
                  ),
                ],
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
