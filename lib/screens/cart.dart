import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../state_management/cart_provider.dart';
import '../state_management/checkout_provider.dart';
import '../state_management/reward_provider.dart';  // Import the reward provider



class CartScreen extends StatefulWidget {

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCartItems();  // fetch from Firestore
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final rewardProvider = Provider.of<RewardProvider>(context);  // Access the reward provider
    final cartItems = cartProvider.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Cart (${cartItems.length})'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body:_isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyCart()
          :  Column(
        children: [
          Expanded(child: _buildCartList(cartProvider, cartItems)),
          _buildCartSummary(cartProvider, rewardProvider, context),  // Pass rewardProvider here
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty_cart.json', height: 200),
          SizedBox(height: 16),
          Text(
            "Your cart is empty!😟",
            style: TextStyle(fontSize: 18, color: Colors.grey[850]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(CartProvider cartProvider, List<CartItem> cartItems) {
    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Dismissible(
          key: ValueKey(item.dressId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: Icon(Icons.delete, color: Colors.white, size: 32),
          ),
          onDismissed: (direction) {
            cartProvider.removeFromCart(item.dressId);
          },
          child: _buildCartItem(cartProvider, item),
        );
      },
    );
  }

  Widget _buildCartItem(CartProvider cartProvider, CartItem item) {
    double subtotal = item.quantity * (item.salePrice ?? item.originalPrice);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/${item.dressId}.jpg',
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 50),
                  _buildQuantityControls(cartProvider, item),
                ],
              ),
              SizedBox(height: 15),
              Text(
                item.dressName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Size: ${item.size}', style: TextStyle(fontSize: 14)),
                      Text('Color: ${item.color}', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Column(children: [
                    Text(
                      'Reward Points: ${item.rewardPoints * item.quantity}',
                      style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Subtotal: PKR ${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartProvider cartProvider, CartItem item) {
    return Column(
      children: [
        SizedBox(height: 10),
        Container(
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey.shade200,
          ),
          child: Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15), topLeft: Radius.circular(15)),
                  color: Colors.grey.shade400,
                ),
                child: IconButton(
                  onPressed: item.quantity > 1
                      ? () => cartProvider.updateQuantity(item.dressId, item.quantity - 1)
                      : null,
                  icon: Icon(Icons.remove_circle, color: Colors.red, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(15), topRight: Radius.circular(15)),
                  color: Colors.grey.shade400,
                ),
                child: IconButton(
                  onPressed: () => cartProvider.updateQuantity(item.dressId, item.quantity + 1),
                  icon: Icon(Icons.add_circle, color: Colors.green, size: 18),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => cartProvider.removeFromCart(item.dressId),
          icon: Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider, RewardProvider rewardProvider, BuildContext context) {
    double subtotal = cartProvider.calculateSubtotal();
    double deliveryFee = subtotal > 0 ? 150.0 : 0.0;
    double total = subtotal + deliveryFee;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow("Subtotal:", "PKR ${subtotal.toStringAsFixed(2)}"),
          _buildPriceRow("Delivery Fee:", "PKR ${deliveryFee.toStringAsFixed(2)}"),
          Divider(),
          _buildPriceRow("Total:", "PKR ${total.toStringAsFixed(2)}", isTotal: true),
          SizedBox(height: 10),
          Text(
            "Total Reward Points Earned: ${cartProvider.getTotalRewardPoints()}",
            style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: subtotal > 0
                  ? () {
                confirmPurchase(cartProvider, rewardProvider, context);  // Pass rewardProvider
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Proceed to Checkout", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 💲 Price Row UI
Widget _buildPriceRow(String title, String value, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      ],
    ),
  );
}

/// ✅ Adds reward points to the wallet upon checkout
void confirmPurchase(
    CartProvider cartProvider,
    RewardProvider rewardProvider,
    BuildContext context,
    ) async {
  double subtotal = cartProvider.calculateSubtotal();
  double deliveryFee = subtotal > 0 ? 150.0 : 0.0;
  double totalAmount = subtotal + deliveryFee;

  int totalRewardPoints = cartProvider.getTotalRewardPoints();
  List<CartItem> cartItems = cartProvider.cartItems;

  try {
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);


    // ✅ Pass totalAmount, cartItems, and totalRewardPoints
    await checkoutProvider.checkout(totalAmount, cartItems, totalRewardPoints);

    // ✅ Update reward points in Firestore is already handled in checkout
    rewardProvider.completePurchase(totalAmount, totalRewardPoints);

    // ✅ Clear cart after successful order
    cartProvider.clearCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Purchase Successful! Points Earned: $totalRewardPoints")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Purchase Failed: $e")),
    );
  }
}
