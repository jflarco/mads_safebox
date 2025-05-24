import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';


class LogoutButton extends ConsumerWidget {
  const LogoutButton ({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final AuthService auth = AuthService();

    return ElevatedButton(
      onPressed: () async {
        //ref.read(userProvider.notifier).state = null;
        await auth.signOut();
      },
      style: ElevatedButton.styleFrom( backgroundColor: Colors.red,),
      child: const Icon(Icons.logout,color: Colors.black,),
    );

  }
}
