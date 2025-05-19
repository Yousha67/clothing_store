import 'dart:convert';
import 'package:clothing_store/auth/app_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import '../auth/app_content.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, uid;
  TextEditingController amountcontroller = TextEditingController();
  List<Map<String, dynamic>> transactionHistory = []; // To store transaction history
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    super.initState();
    ontheload();
  }

  // Fetch the wallet balance from the user's Firestore document
  Future<void> getthesharedpref() async {
    if (uid == null) {
      print("Error: UID is null. Cannot fetch wallet balance.");
      return;
    }
    try {
      var userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          wallet = userDoc.data()?['walletBalance']?.toString() ?? '0';
        });
      } else {
        print("Error: User document does not exist in Firestore.");
      }
    } catch (e) {
      print("Error fetching wallet: $e");
    }
  }

  // Fetch transaction history from Firestore (from a subfield of the user document)
  Future<void> getTransactionHistory() async {
    if (uid == null) return;
    try {
      var userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        List<dynamic> transactions =
            userDoc.data()?['transactionHistory'] ?? [];
        setState(() {
          transactionHistory =
              transactions.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print("Error fetching transaction history: $e");
    }
  }

  // Load initial data
  ontheload() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      await getthesharedpref();
      await getTransactionHistory();
    } else {
      print("Error: No authenticated user found.");
    }
  }

  // Create a payment intent on your backend/Stripe API
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretkey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return jsonDecode(response.body);
    } catch (err) {
      print('Error creating payment intent: ${err.toString()}');
      rethrow;
    }
  }

  String calculateAmount(String amount) {
    final calculatedAmount = int.parse(amount) * 100;
    return calculatedAmount.toString();
  }

  // Open a dialog to allow user to enter custom amount
  Future openEdit() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.cancel),
                ),
                Center(
                  child: Text(
                    'Add Money',
                    style: TextStyle(
                        color: Color(0xFF008080),
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.0),
            Text(
              "Amount",
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 3.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: TextField(
                controller: amountcontroller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Amount",
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 20.0),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  makePayment(amountcontroller.text);
                },
                child: Container(
                  width: 100,
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      color: Color(0xFF008080),
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Center(
                    child: Text(
                      'Pay',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> makePayment(String amount) async {
    try {
      paymentIntent = await createPaymentIntent(amount, 'USD');
      await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntent!['client_secret'],
            style: ThemeMode.dark,
            merchantDisplayName: 'Yousha',
          ));
      displayPaymentSheet(amount);
    } catch (e, s) {
      print('Payment sheet initialization error: $e $s');
    }
  }

  Future<void> displayPaymentSheet(String amount) async {
    try {
      await stripe.Stripe.instance.presentPaymentSheet().then((value) async {
        // Update wallet balance after successful payment (deposit)
        double newWalletBalance = double.parse(wallet!) + double.parse(amount);
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'walletBalance': newWalletBalance,
          'transactionHistory': FieldValue.arrayUnion([
            {
              'amount': amount,
              'transactionType': 'topup',
              'status': 'Added',
              'paymentMethod': 'Stripe',
              'transactionTime': Timestamp.now(),
              // Optional: 'dressName': '' // Include if applicable
            }
          ])
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text("Success",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text("Your payment was successful!",
                textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK",
                    style: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        // Refresh wallet and transaction history
        await getthesharedpref();
        await getTransactionHistory();
        paymentIntent = null;
      }).onError((error, StackTrace) {
        print('Error presenting payment sheet: $error $StackTrace');
      });
    } on stripe.StripeException catch (e) {
      print('Stripe error: $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text('Payment Cancelled'),
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  // Format timestamp to a readable date string
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // <- Important!

      body: wallet == null
          ? Center(child: CircularProgressIndicator())
          : Container(
            margin: EdgeInsets.only(top: 20),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
              ),
              child: Column(
                children: [
                  // Wallet Balance Section (Styled similar to Reward Points)
                  Material(
                    elevation: 15,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade500, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.25),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 55,
                            color: Colors.white,
                          ),
                          SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Wallet",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.4),
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                "PKR: " + wallet!,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade700,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.4),
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  openEdit();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.blueGrey.shade600,
                                  ),
                                  child: Text(
                                    "Add Funds",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),


                  // Add Money Buttons and Edit Dialog

                  SizedBox(height: 15),




                  // Transaction History Header
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Transaction History",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ),
                  ),

                  // Only Transaction History List is Scrollable
                  transactionHistory.isEmpty
                      ? Center(
                    child: Text(
                      "No transaction history available",
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true, // Shrink the list to avoid taking up unnecessary space
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: transactionHistory.length,
                                                  itemBuilder: (context, index) {
                              var transaction = transactionHistory[index];

                              // Parse data
                              Timestamp timestamp = transaction['transactionTime'];
                              String formattedDate = formatTimestamp(timestamp);
                              String dressName = transaction['dressName'] ?? '';
                              String type = transaction['transactionType'] ?? 'unknown';
                              String status = transaction['status'] ?? 'Unknown';
                              String paymentMethod = transaction['paymentMethod'] ?? 'N/A';
                              String amount = transaction['amount'].toString();

                              // Detect icon based on transactionType
                              IconData icon;
                              switch (type.toLowerCase()) {
                                case 'purchase':
                                  icon = Icons.shopping_cart;
                                  break;
                                case 'topup':
                                  icon = Icons.account_balance_wallet;
                                  break;
                                case 'reward redemption':
                                  icon = Icons.redeem;
                                  break;
                                default:
                                  icon = Icons.swap_horiz;
                                  break;
                              }

// Smart status color
                                                    Color statusColor;
                                                    switch (status.toLowerCase()) {
                                                      case 'success':
                                                        statusColor = Colors.green;
                                                        break;
                                                      case 'pending':
                                                        statusColor = Colors.orange;
                                                        break;
                                                      case 'added':
                                                        statusColor = Colors.teal;
                                                        break;
                                                      case 'reward':
                                                        statusColor = Colors.purple;
                                                        break;
                                                      default:
                                                        statusColor = Colors.red;
                                                        break;
                                                    }

// Safe fallbacks
                                                    paymentMethod = transaction['paymentMethod'] ?? (type.toLowerCase() == 'reward redemption' ? 'Wallet Credited By Reward' : 'N/A');


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
                                    backgroundColor: Colors.teal[50],
                                    child: Icon(icon, color: Colors.teal, size: 26),
                                  ),
                                  title: Text(
                                    "PKR $amount",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (type == 'purchase' && dressName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text("Dress: $dressName",
                                              style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text("Method: $paymentMethod",
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(formattedDate,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          bool? confirm = await showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text("Delete Entry"),
                                              content: Text("Are you sure you want to delete this transaction?"),
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
                                                  child: Text("Delete", style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await deleteTransaction(transaction);
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
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
    );
  }


  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'transactionHistory': FieldValue.arrayRemove([transaction])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction deleted")),
      );

      await getTransactionHistory();
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }



}