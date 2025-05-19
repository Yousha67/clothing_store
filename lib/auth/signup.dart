import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home.dart';
import 'login.dart';


class AdvancedSignupScreen extends StatefulWidget {
  @override
  _AdvancedSignupScreenState createState() => _AdvancedSignupScreenState();
}

class _AdvancedSignupScreenState extends State<AdvancedSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _profileImage = pickedImage);
    }
  }
// Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return ""; // Return empty if no image

    try {
      final ref = FirebaseStorage.instance
          .ref('user_profiles/${_emailController.text}.jpg');
      await ref.putFile(File(_profileImage!.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }


  Future<void> _storeUserData(User firebaseUser, String imageUrl) async {
    final newUser = Users(
      uid: firebaseUser.uid,
      name: _nameController.text,
      email: firebaseUser.email!,
      profileImageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      walletBalance: 0.0,
      rewardPoints: 0,
      wishlist: [],
      transactionHistory: [],
      rewardHistory: [],
      orderHistory: [],
      joinedAt: DateTime.now(),
    );

    // Store user data in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set(newUser.toFirestore());
  }


  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w\.-]+@[a-zA-Z\d\.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  bool _validatePhone(String phone) {
    final phoneRegex = RegExp(r"^\+?\d{10,15}$");
    return phoneRegex.hasMatch(phone);
  }

  bool _validatePassword(String password) {
    // Minimum 6 characters, at least one letter and one number
    final passwordRegex = RegExp(r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$");
    return passwordRegex.hasMatch(password);
  }

  bool _validateName(String name) {
    return name.trim().isNotEmpty && name.length >= 3;
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (mounted) {
        setState(() => _isLoading = true); // ✅ Start loading
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        String? imageUrl = await _uploadProfileImage();
        await _storeUserData(userCredential.user!, imageUrl ?? "");

        if (mounted) {
          setState(() => _isLoading = false); // ✅ Stop loading
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Successful')),
        );

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/homepage', (route) => false);
        }

      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Signup Failed")),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        print("Unexpected Error: $e");
      }
    }
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
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
                Lottie.asset('assets/animations/signup.json', height: 250),
                GestureDetector(

                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(File(_profileImage!.path))
                            : AssetImage('assets/images/6.jpg'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(

                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Icon(Icons.camera_alt, size: 20),
                          ),
                          onTap: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  _nameController,
                  "Full Name",
                  Icons.person,
                  hint: "Enter your full name (e.g., John Doe)",
                  validator: (value) {
                    return _validateName(value ?? "") ? null : "Invalid Name";
                  },
                ),
                _buildTextField(
                  _emailController,
                  "Email",
                  Icons.email,
                  hint: "example@gmail.com",
                  validator: (value) {
                    return _validateEmail(value ?? "") ? null : "Invalid Email Format";
                  },
                ),
                _buildTextField(
                  _passwordController,
                  "Password",
                  Icons.lock,
                  hint: "At least 6 characters, including numbers",
                  obscureText: true,
                  validator: (value) {
                    return _validatePassword(value ?? "") ? null : "Weak Password";
                  },
                ),
                _buildTextField(
                  _phoneController,
                  "Phone Number",
                  Icons.phone,
                  hint: "e.g., +1234567890",
                  validator: (value) {
                    return _validatePhone(value ?? "") ? null : "Invalid Phone Number";
                  },
                ),


                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>AdvancedLoginScreen()));
                  },
                  child: Text("Already have an account? Login",style: TextStyle(color: Colors.white),),
                ),
               /* TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
                  },
                  child: Text("Continue as Guest",style: TextStyle(color: Colors.white,)),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          hintText: hint, // Displaying hint text
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }


}
