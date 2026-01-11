import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Using the singleton instance for v7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // --- GOOGLE SIGN IN ---
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the selection UI using the new authenticate method
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) return null; // User closed the popup

      // 2. Get the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create the credential for Firebase
      // FIX: In v7.2.0+, use 'token' instead of 'accessToken'
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken, 
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // --- EMAIL SIGN UP ---
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  // --- EMAIL LOGIN ---
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  // --- LOGOUT ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // --- HELPER: GET CURRENT USER ---
  User? get currentUser => _auth.currentUser;
}