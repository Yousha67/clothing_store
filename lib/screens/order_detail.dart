import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> items = order['items'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Order Details"),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Order Information Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID: ${order['orderId']}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("Payment Method: ${order['paymentMethod']}", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text("Amount Paid: PKR ${order['amount']}", style: TextStyle(fontSize: 16, color: Colors.green)),
                    SizedBox(height: 8),
                    Text("Earned Points: ${order['rewardPointsEarned']}", style: TextStyle(fontSize: 16, color: Colors.blue)),
                    SizedBox(height: 8),
                    Text(
                      "Order Date: ${(order['orderDate'] as Timestamp).toDate().toString().split(" ")[0]}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Items Section
            Divider(height: 30, thickness: 2),
            Text("Items:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            SizedBox(height: 10),
            ...items.map((item) {
              final String dressId = item['dressId'].toString();
              final String imagePath = 'assets/images/${dressId}.jpg';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                          child: Icon(Icons.image_not_supported),
                        );
                      },
                    ),


                  ),
                  title: Text(item['dressName'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Size: ${item['size']}, Color: ${item['color']}"),
                      Text("Quantity: ${item['quantity']}"),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward, color: Colors.deepPurpleAccent),
                  onTap: () {
                    // You can add more details here or navigate to a different screen
                  },
                ),
              );
            }).toList(),

            // Optional: Add a button or section for tracking the order or marking it as completed
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add your tracking or other functionality here
                },
                icon: Icon(Icons.check_circle,color: Colors.white,),
                label: Text("Track Order",style: TextStyle(color: Colors.white,),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
