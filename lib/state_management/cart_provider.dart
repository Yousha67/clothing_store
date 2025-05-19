import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dress.dart';

class CartItem {
  final String dressId;
  final String dressName;
  final double originalPrice;
  final double salePrice;
  final String size;
  final String color;
  final int quantity;
  final int rewardPoints;

  CartItem({
    required this.dressId,
    required this.dressName,
    required this.originalPrice,
    required this.salePrice,
    required this.size,
    required this.color,
    this.quantity = 1,
    this.rewardPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'dressId': dressId,
      'dressName': dressName,
      'originalPrice': originalPrice,
      'salePrice': salePrice,
      'size': size,
      'color': color,
      'quantity': quantity,
      'rewardPoints': rewardPoints,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      dressId: map['dressId'] ?? '',
      dressName: map['dressName'] ?? '',
      originalPrice: map['originalPrice']?.toDouble() ?? 0.0,
      salePrice: map['salePrice']?.toDouble() ?? 0.0,
      size: map['size'] ?? '',
      color: map['color'] ?? '',
      quantity: map['quantity'] ?? 1,
      rewardPoints: map['rewardPoints'] ?? 0,
    );
  }

  CartItem copyWith({
    int? quantity,
    int? rewardPoints,
  }) {
    return CartItem(
      dressId: dressId,
      dressName: dressName,
      originalPrice: originalPrice,
      salePrice: salePrice,
      size: size,
      color: color,
      quantity: quantity ?? this.quantity,
      rewardPoints: rewardPoints ?? this.rewardPoints,
    );
  }
}
class CartProvider with ChangeNotifier {
  final List<CartItem> _cartItems = [];
  int _rewardPointsWallet = 0;

  List<CartItem> get cartItems => _cartItems;
  int get rewardPointsWallet => _rewardPointsWallet;

  // Call this from main app init
  Future<void> initializeCart() async {
    // Example: Load from Firestore or SharedPreferences
    await fetchCartItems(); // or local storage
    notifyListeners();
  }


  /// Fetch cart items from Firestore for the current user
  Future<void> fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document not found.');
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final cartData = data['cart'] as List<dynamic>? ?? [];

      final List<CartItem> fetchedItems = [];

      for (var item in cartData) {
        if (item != null) {
          // Store only the necessary fields for CartItem
          final cartItem = CartItem.fromMap(Map<String, dynamic>.from(item));
          fetchedItems.add(cartItem);
        }
      }

      _cartItems
        ..clear()
        ..addAll(fetchedItems);

      notifyListeners();
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  /// Save current cart state to Firestore
  Future<void> saveCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartData = _cartItems.map((item) => item.toMap()).toList();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'cart': cartData});
    } catch (e) {
      print('Error saving cart items: $e');
    }
  }

  /// Add dress to cart or update quantity if already added
  void addToCart(String dressId, String dressName, double originalPrice, double salePrice, String size, String color, int rewardPoints) {
    final index = _cartItems.indexWhere(
          (item) =>
      item.dressId == dressId &&
          item.size == size &&
          item.color == color,
    );

    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 1,
      );
    } else {
      _cartItems.add(CartItem(
        dressId: dressId,
        dressName: dressName,
        originalPrice: originalPrice,
        salePrice: salePrice,
        size: size,
        color: color,
        rewardPoints: rewardPoints,
      ));
    }

    saveCartItems();
    notifyListeners();
  }

  /// Remove an item by dress ID
  void removeFromCart(String dressId) {
    _cartItems.removeWhere((item) => item.dressId == dressId);
    saveCartItems();
    notifyListeners();
  }

  /// Update quantity of a specific cart item
  void updateQuantity(String dressId, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item.dressId == dressId);

    if (index != -1) {
      if (newQuantity > 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
      } else {
        _cartItems.removeAt(index);
      }

      saveCartItems();
      notifyListeners();
    }
  }

  double calculateSubtotal() {
    return _cartItems.fold(0.0, (sum, item) {
      double itemPrice = item.salePrice != 0 ? item.salePrice : item.originalPrice;
      return sum + (item.quantity * itemPrice);
    });
  }

  /// Get total price of cart
  double get totalPrice {
    return _cartItems.fold(
      0.0,
          (sum, item) =>
      sum + ((item.salePrice != 0 ? item.salePrice : item.originalPrice) * item.quantity),
    );
  }

  /// Get total reward points from cart
  int getTotalRewardPoints() {
    return _cartItems.fold(
      0,
          (total, item) => total + (item.rewardPoints * item.quantity),
    );
  }

  /// Add earned reward points to user's wallet
  void addRewardPointsToWallet() {
    _rewardPointsWallet += getTotalRewardPoints();
    notifyListeners();
  }

  /// Handle checkout process
  void completePurchase() {
    addRewardPointsToWallet();
    clearCart();
    saveCartItems();
    notifyListeners();
  }

  /// Clear entire cart
  void clearCart() {
    _cartItems.clear();
    saveCartItems();
    notifyListeners();
  }
}
