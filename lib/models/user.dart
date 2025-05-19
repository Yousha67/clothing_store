import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String uid;
  final String name;
  final String email;
  final double walletBalance;
  final int rewardPoints;
  final String? profileImageUrl;
  final List<String> wishlist;
  final List<Map<String, dynamic>> orderHistory;
  final List<Map<String, dynamic>> transactionHistory; // New field for transaction history
  final List<Map<String, dynamic>> rewardHistory; // New field for reward history
  final DateTime joinedAt;

  Users({
    required this.uid,
    required this.name,
    required this.email,
    this.walletBalance = 0,
    this.rewardPoints = 0,
    this.profileImageUrl,
    this.wishlist = const [],
    this.orderHistory = const [],
    this.transactionHistory = const [], // Default to empty list
    this.rewardHistory = const [], // Default to empty list
    required this.joinedAt,
  });

  factory Users.fromFirestore(Map<String, dynamic> data, String userId) {
    return Users(
      uid: userId,
      name: data['name'],
      email: data['email'],
      walletBalance: data['walletBalance'] ?? 0,
      rewardPoints: (data['rewardPoints'] ?? 0).toInt(),  // Ensure it's an int
      profileImageUrl: data['profileImageUrl'],
      wishlist: List<String>.from(data['wishlist'] ?? []),
      orderHistory: List<Map<String, dynamic>>.from(data['orderHistory'] ?? []),
      transactionHistory: List<Map<String, dynamic>>.from(data['transactionHistory'] ?? []), // Added transactionHistory
      rewardHistory: List<Map<String, dynamic>>.from(data['rewardHistory'] ?? []), // Added rewardHistory
      joinedAt: (data['joinedAt'] as Timestamp).toDate(), // ✅ Fixed
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "email": email,
      "walletBalance": walletBalance,
      "rewardPoints": rewardPoints,
      "profileImageUrl": profileImageUrl,
      "wishlist": wishlist,
      "orderHistory": orderHistory,
      "transactionHistory": transactionHistory, // Added transactionHistory
      "rewardHistory": rewardHistory, // Added rewardHistory
      "joinedAt": Timestamp.fromDate(joinedAt), // ✅ Fixed
    };
  }
}
