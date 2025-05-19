import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoading = true;
      orders.clear();
    });

    user = _auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to view order history.')),
        );
      });
      setState(() => _isLoading = false);
      return;
    }

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('orderDate', descending: true) // Ordering by orderDate
          .get();

      setState(() {
        orders = snapshot.docs
            .map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id, // Document ID for referencing
        })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch orders: $e')),
      );
    }
  }

  Future<void> _clearOrderHistory() async {
    try {
      for (var order in orders) {
        await _firestore.collection('orders').doc(order['id']).delete();
      }
      setState(() {
        orders.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order history cleared successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear order history: $e')),
      );
    }
  }

  Widget _buildOrderHistorySection() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (user == null) {
      return Center(child: Text('Guest users cannot view order history.'));
    } else if (orders.isEmpty) {
      return Center(child: Text('No orders found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _clearOrderHistory,
            icon: Icon(Icons.delete_forever, color: Colors.white),
            label: Text("Clear Order History", style: TextStyle(fontSize: 16,color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(Icons.shopping_bag, size: 40, color: Colors.deepPurple), // Placeholder icon
                    title: Text(order['orderId'] ?? 'Order ID'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Date: ${(order['orderDate'] as Timestamp).toDate().toString().split(" ")[0]}'),
                        Text('Amount: PKR ${order['amount'] ?? '0'}'),
                        Text('Status: ${order['status'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("View", style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _buildOrderHistorySection(),
    );
  }
}
