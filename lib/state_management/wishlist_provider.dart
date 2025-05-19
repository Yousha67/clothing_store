import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistProvider extends ChangeNotifier {
  Set<String> _wishlist = {};
  Set<String> get wishlist => _wishlist;

  final String _wishlistKey = 'user_wishlist';

  WishlistProvider() {
    _loadWishlist();
  }

  // Load wishlist from SharedPreferences and Firestore
  void _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWishlist = prefs.getStringList(_wishlistKey) ?? [];

    _wishlist = savedWishlist.toSet();
    notifyListeners();

    await _syncWishlistWithFirestore();
  }

  // Add or remove dress from wishlist
  Future<void> toggleWishlist(String dressId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_wishlist.contains(dressId)) {
      _wishlist.remove(dressId);
    } else {
      _wishlist.add(dressId);
    }

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_wishlistKey, _wishlist.toList());

    // Sync with Firestore
    await _syncWishlistWithFirestore();

    notifyListeners();
  }

  // Sync wishlist with Firestore
  Future<void> _syncWishlistWithFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'wishlist': FieldValue.arrayUnion(_wishlist.toList()),
    }, SetOptions(merge: true));
  }

  // Load wishlist from Firestore
  Future<void> loadWishlistFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final List<String> wishlistFirestore = List<String>.from(snapshot.data()?['wishlist'] ?? []);

    _wishlist = wishlistFirestore.toSet();
    notifyListeners();
  }

  // Remove dress from wishlist
  Future<void> removeFromWishlist(String dressId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _wishlist.remove(dressId);

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_wishlistKey, _wishlist.toList());

    // Sync with Firestore
    await _syncWishlistWithFirestore();

    notifyListeners();
  }
}
