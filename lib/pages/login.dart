import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safestep/pages/sign_up.dart';
import 'package:safestep/pages/map_page.dart'; // Redirect to MapPage after login
import 'package:safestep/services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  bool isLoading = false;

  void validateAndSubmit() async {
    // 1. Reset UI Errors
    setState(() {
      emailError = emailController.text.trim().isEmpty ? "Email is required" : null;
      passwordError = passwordController.text.trim().isEmpty ? "Password is required" : null;
    });

    if (emailError != null || passwordError != null) return;

    setState(() => isLoading = true);

    // 2. Call the updated AuthService
    final result = await AuthService().login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    // 3. Handle the result
    if (result == "success") {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      }
    } else {
      setState(() {
        isLoading = false;
        // Map Firebase error codes to human-friendly messages
        if (result == 'user-not-found' || result == 'invalid-credential') {
          emailError = "No account found with this email.";
        } else if (result == 'wrong-password') {
          passwordError = "Incorrect password.";
        } else if (result == 'invalid-email') {
          emailError = "Please enter a valid email address.";
        } else if (result == 'user-disabled') {
          emailError = "This account has been disabled.";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: ${result ?? 'Unknown error'}")),
          );
        }
      });
    }
  }

  void handleGoogleLogin() async {
    setState(() => isLoading = true);
    User? user = await AuthService().signInWithGoogle();
    
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C222D),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Log in to continue your safe journey",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 32),
                
                _inputField(
                  hint: "Email",
                  icon: Icons.email,
                  controller: emailController,
                  errorText: emailError,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                _inputField(
                  hint: "Password",
                  icon: Icons.lock,
                  obscure: true,
                  controller: passwordController,
                  errorText: passwordError,
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : validateAndSubmit,
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        "Log In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFF374151))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "or continue with",
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF374151))),
                  ],
                ),
                const SizedBox(height: 20),
                
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF374151)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : handleGoogleLogin,
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    "Log in with Google",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  },
                  child: const Text(
                    "Don’t have an account? Sign up",
                    style: TextStyle(color: Color(0xFF22C55E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextEditingController? controller,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFF111827),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: const Color(0xFF22C55E)),
        ),
      ),
    );
  }
}