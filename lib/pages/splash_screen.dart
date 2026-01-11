import 'package:flutter/material.dart';
import 'package:safestep/pages/sign_up.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (_) => const SignUp()), );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C222D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.verified_user,
                  color: Color(0xFF22C55E),
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "SafeStep",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Walk Safe. Travel Safe.",
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
