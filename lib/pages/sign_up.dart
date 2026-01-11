import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safestep/pages/login.dart';
import 'package:safestep/pages/map_page.dart';
import 'package:safestep/services/auth_service.dart'; // Ensure this path is correct

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? nameError;
  String? emailError;
  String? passwordError;
  bool isLoading = false;

  /// Handles Email/Password Registration
  void validateAndSubmit() async {
    // 1. Reset Errors and start loading
    setState(() {
      nameError = nameController.text.trim().isEmpty ? "Full Name is required" : null;
      emailError = emailController.text.trim().isEmpty ? "Email is required" : null;
      passwordError = passwordController.text.trim().isEmpty ? "Password is required" : null;
    });

    if (nameError != null || emailError != null || passwordError != null) return;

    setState(() => isLoading = true);

    // 2. Call Auth Service
    final result = await AuthService().signUp(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    // 3. Handle Result
    if (result == "success") {
      // Optional: Update user display name here if needed
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      }
    } else {
      setState(() {
        isLoading = false;
        // Specific Firebase Error Handling
        if (result == 'email-already-in-use') {
          emailError = "This email is already registered.";
        } else if (result == 'weak-password') {
          passwordError = "The password is too weak.";
        } else if (result == 'invalid-email') {
          emailError = "Please enter a valid email address.";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${result ?? 'An unknown error occurred'}")),
          );
        }
      });
    }
  }

  /// Handles Google Sign In
  void handleGoogleSignUp() async {
    setState(() => isLoading = true);
    
    User? user = await AuthService().signInWithGoogle();
    
    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In failed or was cancelled.")),
        );
      }
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
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to stay safe on every step",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 32),
                
                _inputField(
                  hint: "Full Name",
                  icon: Icons.person,
                  controller: nameController,
                  errorText: nameError,
                ),
                const SizedBox(height: 16),
                
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
                        "Sign Up",
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
                  onPressed: isLoading ? null : handleGoogleSignUp,
                  icon: const FaIcon(
                    FontAwesomeIcons.google,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    "Sign up with Google",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Log in",
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
          borderSide: const BorderSide(color: Color(0xFF22C55E)),
        ),
      ),
    );
  }
}