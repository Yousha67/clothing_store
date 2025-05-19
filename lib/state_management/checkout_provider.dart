import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cart_provider.dart';

class CheckoutProvider with ChangeNotifier {
  String? wallet;
  String? uid;

  // Function to update the wallet and transaction history
  Future<void> checkout(double totalAmount, List<CartItem> cartItems, int earnedRewardPoints) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'User not logged in';

    final uid = user.uid;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final currentWallet = userDoc.data()?['walletBalance'] ?? 0.0;

    if (currentWallet < totalAmount) throw 'Insufficient balance!';

    // Deduct wallet
    final newWalletBalance = currentWallet - totalAmount;

    // Update wallet + rewardPoints
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'walletBalance': newWalletBalance,
    });

    // Add to transaction history
    await _addTransactionToHistory(totalAmount);

    // Save order
    await saveOrder(cartItems, totalAmount, earnedRewardPoints);

    notifyListeners();
  }

  // Helper method to add a transaction to the transactionHistory field
  Future<void> _addTransactionToHistory(double totalAmount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;

      try {
        // Define the new transaction
        Map<String, dynamic> newTransaction = {
          'amount': totalAmount.toString(),
          'transactionType': 'purchase',
          'status': 'Success',
          'paymentMethod': 'Wallet',
          'transactionTime': Timestamp.now(),
        };

        // Push the transaction into Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'transactionHistory': FieldValue.arrayUnion([newTransaction])
        });

        print("Purchase transaction added successfully!");
      } catch (e) {
        print("Error adding purchase transaction: $e");
      }
    }
  }

  Future<void> saveOrder(List<CartItem> cartItems, double totalAmount, int rewardPoints) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

    final orderData = {
      'orderId': orderId,
      'userId': user.uid,
      'items': cartItems.map((item) => item.toMap()).toList(),
      'amount': totalAmount,
      'rewardPointsEarned': rewardPoints,
      'paymentMethod': 'Wallet',
      'status': 'Processing',
      'orderDate': Timestamp.now(),
      'deliveryDate': null, // Can be updated later
    };

    await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
  }

}
