// KULLANIM
// BENDE OLAN BİR RUST KODUNU ÇALIŞTIR.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TvVideoApp());
}

class TvVideoApp extends StatelessWidget {
  const TvVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Network Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routerConfig: appRouter,
    );
  }
}
