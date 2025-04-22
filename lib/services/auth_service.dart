import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up function with email verification
  Future<User?> signUpUser(String email, String password, String role, String username, String school) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        // Save user data under the correct school collection
        await _firestore
            .collection('schools')
            .doc(school)
            .collection(role)
            .doc(user.uid)
            .set({
          'email': email,
          'username': username,
          'role': role,
          'uid': user.uid,
          'createdAt': DateTime.now(),
        });
      }

      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // Login function with email verification check
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        await logout(); // log out unverified user
        return null;
      }

      return user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
