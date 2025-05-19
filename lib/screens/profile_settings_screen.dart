import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../state_management/theme_ptovider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? user;
  Map<String, dynamic>? userData;
  bool _isLoading = false;
  bool _showLottie = false;
  bool _isDarkMode = false;
  bool _showEditFields = false; // Add this to your state class
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    user = _auth.currentUser;
    if (user != null) {
      var snapshot = await _firestore.collection('users').doc(user!.uid).get();
      setState(() => userData = snapshot.data());
      _nameController.text = userData?['name'] ?? '';
      _emailController.text = userData?['email'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfileImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() { _isLoading = true; _showLottie = true; });
      try {
        final ref = _storage.ref().child('profileImages/${user!.uid}.jpg');
        await ref.putFile(File(pickedImage.path));
        String imageUrl = await ref.getDownloadURL();
        await _firestore.collection('users').doc(user!.uid).update({'profileImage': imageUrl});
        setState(() => userData?['profileImage'] = imageUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
      setState(() { _isLoading = false; _showLottie = false; });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showMessage("Please fill in both fields.");
      return;
    }

    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
      });
      setState(() {
        userData?['name'] = _nameController.text;
        userData?['email'] = _emailController.text;
      });
      _showMessage('Profile updated successfully!');
    } catch (e) {
      _showMessage('Failed to update profile: $e');
    }
  }

  Future<void> _changePassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: userData?['email']);
      _showMessage('Password reset email sent.');
    } catch (e) {
      _showMessage('Failed to send reset email.');
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _deleteAccount() async {
    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: await _promptPassword(), // Prompt user for password
      );

      await user!.reauthenticateWithCredential(credential);


      // Delete user data from Firestore
      await _firestore.collection('users').doc(user!.uid).delete();
      // Delete user from Firebase Auth
      await user!.delete();

      // Navigate to signup/login screen
      Navigator.pushReplacementNamed(context, '/signup');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showMessage('Please re-login to delete your account.');
      } else {
        _showMessage('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      _showMessage('Error occurred: $e');
    }
  }

  Future<String> _promptPassword() async {
    String password = '';
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController _passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Re-authentication Required'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Enter your password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = _passwordController.text;
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _submitFeedback() async {
    String feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      _showMessage('Please write your feedback.');
      return;
    }

    try {
      await _firestore.collection('feedback').add({
        'userId': user?.uid,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showMessage('Thank you for your feedback!');
      _feedbackController.clear();
    } catch (e) {
      _showMessage('Failed to send feedback.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: Lottie.asset('assets/animations/loader.json', height: 120))
          : ListView(
        padding: EdgeInsets.all(16),
        children: [
          _showLottie
              ? Lottie.asset('assets/animations/avatar.json', height: 120)
              : Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _updateProfileImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: userData?['profileImage'] != null
                        ? NetworkImage(userData!['profileImage'])
                        : AssetImage('assets/images/6.jpg') as ImageProvider,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(userData != null ? userData!['name'] : "Guest User", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userData != null ? userData!['email'] : "Limited access available"),
          SizedBox(height: 15),
          // Toggle Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showEditFields = !_showEditFields;
              });
            },
            icon: Icon(_showEditFields ? Icons.close : Icons.edit),
            label: Text(_showEditFields ? "Cancel Edit" : "Edit Profile Info"),
          ),

          // Conditionally show name/email fields
          if (_showEditFields) ...[
            SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Save Changes"),
            ),
          ],


          SizedBox(height: 15),
          SwitchListTile(
            value: context.watch<ThemeProvider>().isDarkMode,
            title: Text("Dark Mode"),
            onChanged: (value) {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.blue),
            title: Text("Change Password"),
            onTap: _changePassword,
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: _logout,
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text("Delete Account"),
            onTap: _deleteAccount,
          ),
          SizedBox(height: 30),
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(labelText: 'Your Feedback'),
            maxLines: 3,
          ),
          ElevatedButton(
            onPressed: _submitFeedback,
            child: Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }
}
