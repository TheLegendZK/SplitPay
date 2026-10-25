import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/core/theme/theme.dart';
import 'package:splitpay/features/auth/data/auth_provider.dart';
import 'package:splitpay/features/auth/presentation/auth_screen.dart';
import 'package:splitpay/features/groups/presentation/group_screen.dart';
import 'package:splitpay/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SplitPayApp()));
}

class SplitPayApp extends StatelessWidget {
  const SplitPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SplitPay',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) => user != null ? const GroupScreen() : const AuthScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, _) => const AuthScreen(),
    );
  }
}
