import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardProvider with ChangeNotifier {
  double _walletBalance = 5000.0; // Initial wallet balance
  int _rewardPoints = 0; // Initial reward points
  List<Transaction> _rewardHistory = []; // List to hold reward points history
  List<Transaction> _transactionHistory = []; // List to hold transaction history

  double get walletBalance => _walletBalance;
  int get rewardPoints => _rewardPoints;
  List<Transaction> get rewardHistory => _rewardHistory;
  List<Transaction> get transactionHistory => _transactionHistory;

  // Method to add points to the wallet
  Future<void> addRewardPoints(int points, String title) async {

    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

        // Use runTransaction for atomic operations
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Get the current document snapshot
          DocumentSnapshot snapshot = await transaction.get(userRef);

          // Check if the document exists
          if (!snapshot.exists) {
            throw Exception("User document does not exist");
          }

          // Get current reward points and reward history from Firestore
          var currentRewardPoints = snapshot['rewardPoints'] ?? 0;
          var currentRewardHistory = List.from(snapshot['rewardHistory'] ?? []);

          // Prepare the new reward history entry
          var newHistoryEntry = {
            'points': points,
            'title': title,
            'transactionTime': Timestamp.now(),
          };
          print("Current Points: $currentRewardPoints, Points to Add: $points");

          // Update the user's reward points and reward history in Firestore
          transaction.update(userRef, {
            'rewardPoints': currentRewardPoints + points,  // Increment reward points
            'rewardHistory': FieldValue.arrayUnion([newHistoryEntry]),  // Add new history entry
          });
          _rewardPoints += points;
        });



      } catch (e) {
        print('Error adding reward points: $e');
      }
    }
  }


  // Method to initialize the data from Firestore
  Future<void> initialize() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();

        _walletBalance = data?['walletBalance'] ?? 0;
        _rewardPoints = (data?['rewardPoints'] ?? 0).toInt();

        // Fetching reward history from Firestore and mapping to Transaction objects
        _rewardHistory = List<Map<String, dynamic>>.from(data?['rewardHistory'] ?? [])
            .map((map) => Transaction(
          description: map['title'],
          amount: map['points']?.toDouble() ?? 0,
          date: (map['transactionTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ))
            .toList();

        // Fetching transaction history from Firestore and mapping to Transaction objects
        _transactionHistory = List<Map<String, dynamic>>.from(data?['transactionHistory'] ?? [])
            .map((map) => Transaction(
          description: map['transactionType'],
          amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
          date: (map['transactionTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ))
            .toList();

        notifyListeners();
      } catch (e) {
        print('Error initializing user data: $e');
      }
    }
  }

  // Method to record a transaction in the transaction history
  void addTransaction(String description, double amount, DateTime date) {
    _transactionHistory.add(Transaction(description: description, amount: amount, date: date));
    notifyListeners();
  }

  // Method to complete a purchase and reward points
  void completePurchase(double purchaseAmount, int earnedRewardPoints) {
  // Deduct the purchase amount from wallet
    addRewardPoints(earnedRewardPoints, 'Purchase Reward Points');  // Add reward points to user
    addTransaction('Purchase - ${purchaseAmount.toStringAsFixed(2)}', purchaseAmount, DateTime.now());
  }

}

class Transaction {
  final String description;
  final double amount;
  final DateTime date;

  Transaction({required this.description, required this.amount, required this.date});
}
