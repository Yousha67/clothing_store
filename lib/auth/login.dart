import 'package:clothing_store/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home.dart';
import 'forget_pass.dart';

class AdvancedLoginScreen extends StatefulWidget {
  @override
  _AdvancedLoginScreenState createState() => _AdvancedLoginScreenState();
}

class _AdvancedLoginScreenState extends State<AdvancedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Email Validation
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w\.-]+@[a-zA-Z\d\.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  // Password Validation
  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  // Login Logic using Firebase Authentication
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() => _isLoading = true); // ✅ Start loading
      }

      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Successful")),
        );

        // Navigate to Home Screen
        Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);

      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false); // ✅ Start loading
        }

        // Handle specific errors
        String errorMessage;
        switch (e.code) {
          case "user-not-found":
            errorMessage = "No user found with this email.";
            break;
          case "wrong-password":
            errorMessage = "Incorrect password.";
            break;
          case "invalid-email":
            errorMessage = "Invalid email format.";
            break;
          default:
            errorMessage = "An unexpected error occurred.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  void dispose() {

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Lottie.asset('assets/animations/login.json', height: 300),
                SizedBox(height: 20),

                // Email Input
                _buildTextField(
                  _emailController,
                  "Email",
                  Icons.email,
                  hint: "e.g., example@gmail.com",
                  validator: (value) {
                    return _validateEmail(value ?? "")
                        ? null
                        : "Enter a valid email (e.g., example@gmail.com)";
                  },
                ),

                // Password Input
                _buildTextField(
                  _passwordController,
                  "Password",
                  Icons.lock,
                  obscureText: true,
                  hint: "Minimum 6 characters",
                  validator: (value) {
                    return _validatePassword(value ?? "")
                        ? null
                        : "Password must be at least 6 characters";
                  },
                ),
                SizedBox(height: 20),

                // Login Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  child: Text("Login", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgetPasswordScreen()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // Signup Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdvancedSignupScreen()),
                    );
                  },
                  child: Text(
                    "Create New Account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Input Field Builder with Hints
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscureText = false,
        required String? Function(String?) validator,
        String? hint,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
