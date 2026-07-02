import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/tv_button.dart';

class MovieNotFoundScreen extends StatelessWidget {
  const MovieNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Film bilgisi bulunamadı',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            TvButton(
              icon: Icons.arrow_back_rounded,
              size: 40,
              autofocus: true,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
