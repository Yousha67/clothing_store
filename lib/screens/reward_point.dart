import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class RewardPointsPage extends StatefulWidget {
  const RewardPointsPage({Key? key}) : super(key: key);

  @override
  _RewardPointsPageState createState() => _RewardPointsPageState();
}

class _RewardPointsPageState extends State<RewardPointsPage> {
  int rewardPoints = 0;
  List<Map<String, dynamic>> rewardsHistory = [];
  String? uid;
  Users? user;

  @override
  void initState() {
    super.initState();
    getUserUid();
  }

  Future<void> getUserUid() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      uid = firebaseUser.uid;
      await fetchUserData();
      await fetchRewardsHistory();
    }
  }

  Future<void> fetchUserData() async {
    if (uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          user = Users.fromFirestore(userDoc.data() as Map<String, dynamic>, uid!);
          setState(() {
            rewardPoints = (user?.rewardPoints ?? 0).toInt();
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> fetchRewardsHistory() async {
    if (uid != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          // Fetching rewardHistory as a subfield of the user's document
          var userData = userDoc.data() as Map<String, dynamic>;
          var rewardHistoryData = userData['rewardHistory'] ?? [];
          setState(() {
            rewardsHistory = List<Map<String, dynamic>>.from(rewardHistoryData);
          });
        }
      } catch (e) {
        print('Error fetching reward history: $e');
      }
    }
  }

  Future<void> addRewardPoints(int points, String title) async {
    if (uid != null) {
      try {
        // Updating reward points in the user's document
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'rewardPoints': FieldValue.increment(points),
          'rewardHistory': FieldValue.arrayUnion([
            {
              'points': points,
              'title': title,
              'transactionTime': Timestamp.now(),
            }
          ])
        });

        await fetchUserData();
        await fetchRewardsHistory();
      } catch (e) {
        print('Error adding reward points: $e');
      }
    }
  }
  Future<void> removeRewardEntry(Map<String, dynamic> reward) async {
    if (uid == null) return;

    try {
      // Just remove the reward entry from the array, nothing else
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'rewardHistory': FieldValue.arrayRemove([reward])
      });

      // ❌ Removed the code that subtracts rewardPoints
      // ✅ Keep the current rewardPoints as-is

      await fetchRewardsHistory();
    } catch (e) {
      print('Error removing reward entry: $e');
    }
  }

  Future<void> redeemPoints() async {
    if (rewardPoints < 500) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Not Enough Points'),
          content: Text('You need at least 500 points to redeem.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
          ],
        ),
      );
      return;
    }

    bool isStandard = true;
    int selectedSets = 1;
    int customPoints = 500;
    int maxSets = rewardPoints ~/ 500;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Redeem Reward Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [isStandard, !isStandard],
                onPressed: (index) => setState(() => isStandard = index == 0),
                children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Standard (500x)")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Custom")),
                ],
              ),
              SizedBox(height: 15),
              if (isStandard) ...[
                Text('You have $rewardPoints points'),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: selectedSets > 1
                          ? () => setState(() => selectedSets--)
                          : null,
                    ),
                    Text('$selectedSets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add_circle),
                      onPressed: selectedSets < maxSets
                          ? () => setState(() => selectedSets++)
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Rs:${selectedSets * 500} will be added to wallet'),
              ] else ...[
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Enter points to redeem"),
                  onChanged: (value) {
                    int val = int.tryParse(value) ?? 0;
                    if (val <= rewardPoints) setState(() => customPoints = val);
                  },
                ),
                SizedBox(height: 8),
                Text('Rs:$customPoints will be added to wallet'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                int finalPoints = isStandard ? selectedSets * 500 : customPoints;
                if (finalPoints >= 500 && finalPoints <= rewardPoints) {
                  Navigator.pop(context, finalPoints);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text('Redeem',style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    ).then((redeemPoints) async {
      if (redeemPoints != null && redeemPoints is int) {
        try {
          final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(userRef);
            if (!snapshot.exists) throw Exception("User not found");

            int currentPoints = (snapshot['rewardPoints'] ?? 0).toInt();
            double currentWallet = (snapshot['walletBalance'] ?? 0).toDouble();

            double redeemAmount = redeemPoints.toDouble();

            if (currentPoints < redeemPoints) throw Exception("Insufficient points");

            transaction.update(userRef, {
              'rewardPoints': currentPoints - redeemPoints,
              'walletBalance': currentWallet + redeemAmount,
              'rewardHistory': FieldValue.arrayUnion([
                {
                  'points': -redeemPoints,
                  'title': 'Redeemed $redeemPoints Points for ₹$redeemAmount Wallet',
                  'transactionTime': Timestamp.now(),
                }
              ]),
              'transactionHistory': FieldValue.arrayUnion([
                {
                  'transactionType': 'Reward Redemption',
                  'amount': redeemAmount,
                  'status': 'Reward',
                  'transactionTime': Timestamp.now(),
                }
              ]),
            });
          });

          await fetchUserData();
          await fetchRewardsHistory();

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Success'),
              content: Text('₹$redeemPoints added to your wallet!'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
              ],
            ),
          );
        } catch (e) {
          print('Redemption error: $e');
        }
      }
    });
  }


  String formatTimestamp(Timestamp timestamp) {
    // Format the timestamp into a more readable string using intl
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date); // Custom format
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.teal.shade600,Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Total Reward Points", style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text(
                          "$rewardPoints",
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rewardPoints >= 500
                          ? "🎉 You have enough points to redeem Rs:500!"
                          : "⚠ You need at least 500 points to redeem Rs:500 to your wallet.",
                      style: TextStyle(
                        color: rewardPoints >= 500 ? Colors.lightGreenAccent : Colors.yellowAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: rewardPoints / 500.0 > 1 ? 1 : rewardPoints / 500.0,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      color: rewardPoints >= 500 ? Colors.lightGreenAccent : Colors.yellowAccent,
                      minHeight: 6,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${rewardPoints >= 500 ? 500 : rewardPoints}/500 points",
                      style: TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: rewardPoints >= 50 ? redeemPoints : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                  ),
                  child: Text("Redeem Points",style: TextStyle(color: Colors.black),),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Rewards History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: rewardsHistory.isEmpty
                ? Center(child: Text("No reward points history", style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
              itemCount: rewardsHistory.length,
              itemBuilder: (context, index) {
                final reward = rewardsHistory[index];
                final int points = reward["points"];
                final bool isPositive = points >= 0;
                Timestamp timestamp = reward["transactionTime"];
                String formattedTime = formatTimestamp(timestamp);

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isPositive ? Colors.green[50] : Colors.red[50],
                      child: Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      reward["title"],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Column(

                      children: [
                        Text(
                          "${points > 0 ? '+' : ''}$points pts",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Delete Entry"),
                                content: Text("Are you sure you want to delete this reward entry?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    child: Text("Delete",style: TextStyle(color: Colors.white),),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await removeRewardEntry(reward);
                            }
                          },
                          child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          ),
        ],
      ),
    );
  }
}
