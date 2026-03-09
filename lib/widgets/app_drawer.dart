import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';
import 'package:nexora_final/screens/terms_screen.dart';
import 'package:nexora_final/screens/help_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).user;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth?.firstName ?? auth?.username ?? 'Guest'),
              accountEmail: Text(auth?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('assets/user_icon.jpg'),
              ),
            ),
            ListTile(leading: const Icon(Icons.edit), title: const Text('Edit Profile'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileInfoScreen()))),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen()))),
            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text('Terms & Policies'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
