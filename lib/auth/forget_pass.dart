import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Validate Email
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w\.-]+@[a-zA-Z\d\.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  // Reset Password with Debug
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Attempt to send reset email
        await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("If the email exists, a reset link has been sent.")),
        );

        // Navigate back to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdvancedLoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);

        // Specific error handling
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = "No user found with this email.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email format.";
        } else {
          errorMessage = "An unexpected error occurred.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
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
                SizedBox(height: 40),
                Lottie.asset('assets/animations/forget.json', height: 280),
                SizedBox(height: 20),

                // Email Input
                _buildTextField(
                  _emailController,
                  "Email",
                  Icons.email,
                  hint: "e.g., example@gmail.com",
                ),
                SizedBox(height: 20),

                // Reset Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _resetPassword,
                  child: Text("Reset Password", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),

                // Back to Login Button
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdvancedLoginScreen()),
                    );
                  },
                  child: Text(
                    "Back to Login",
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

  // Input Field Builder
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
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
        validator: (value) => _validateEmail(value ?? "")
            ? null
            : "Enter a valid email (e.g., example@gmail.com)",
      ),
    );
  }
}
