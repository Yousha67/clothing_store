import 'package:flutter/material.dart';
import '../models/dress.dart';
import '../state_management/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProductDetailScreen extends StatefulWidget {
  final Dress dress;

  ProductDetailScreen({required this.dress});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? selectedSize;
  String? selectedColor;
  double userRating = 0; // Store user's rating
  double totalRating = 0; // Sum of all ratings
  int ratingCount = 0; // Number of ratings
  bool showAllReviews = false;
  TextEditingController reviewController = TextEditingController();
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    selectedSize = (widget.dress.sizes.isNotEmpty) ? widget.dress.sizes.first : null;
    selectedColor = (widget.dress.colors.isNotEmpty) ? widget.dress.colors.first : null;

    // Fetch reviews from Firestore instead of hardcoding them
    fetchReviews();
  }

  // Fetch reviews from Firestore
  void fetchReviews() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.dress.id)
          .collection('reviews')
          .get();
      setState(() {
        reviews = reviewsSnapshot.docs.map((doc) {
          return {
            "name": doc['name'],
            "review": doc['review'],
            "rating": doc['rating'],
          };
        }).toList();

        // Calculate initial total rating and count
        totalRating = reviews.fold(0, (sum, review) => sum + (review['rating'] as double));
        ratingCount = reviews.length;
      });
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  // Submit a review
  void submitReview() async {
    String reviewText = reviewController.text.trim();
    if (reviewText.isNotEmpty && userRating > 0) {
      // Get the current user's UID and fetch their name from Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String userName = "Anonymous";  // Default to "Anonymous" if name not found

      if (uid != null) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final userData = userDoc.data();
          if (userData != null && userData['name'] != null) {
            userName = userData['name'];  // Fetch the actual username from Firestore
          }
        } catch (e) {
          print("Error fetching user data: $e");
        }
      }

      setState(() {
        reviews.add({"name": userName, "review": reviewText, "rating": userRating});
        totalRating += userRating;
        ratingCount++;
        reviewController.clear();
      });

      // Add review to Firestore
      FirebaseFirestore.instance.collection('products')
          .doc(widget.dress.id)
          .collection('reviews')
          .add({
        'name': userName,
        'review': reviewText,
        'rating': userRating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Review submitted!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please provide a rating before submitting your review!")));
    }
  }

  double get generalRating => ratingCount > 0 ? totalRating / ratingCount : 0;

  void updateRating(double rating) {
    setState(() {
      userRating = rating;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You rated ${widget.dress.name} ${rating.toStringAsFixed(1)} stars!")),
    );
  }

  // Add to cart logic
  void addToCart(Dress dress, String selectedSize, String selectedColor) {
    if (selectedSize == null || selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select size and color")));
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);


    cartProvider.addToCart(
      dress.id,
      dress.name,
      dress.originalPrice,
      dress.salePrice ?? dress.originalPrice,
      selectedSize,
      selectedColor,
      dress.rewardPoints,
    );


    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.dress.name} added to cart!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dress.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dress Image
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.dress.imageUrl.startsWith("http")
                        ? Image.network(
                      widget.dress.imageUrl,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 450,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    )
                        : Image.asset(
                      widget.dress.imageUrl,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 450,
                    ),
                  ),
                ),
              ),

              // Product Details
              SizedBox(height: 16),
              Text(widget.dress.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(widget.dress.category, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text("Brand: ${widget.dress.brand}", style: TextStyle(fontSize: 16)),
              Text("Material: ${widget.dress.material}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 12),

              // Price Section
              if (widget.dress.isOnSale && widget.dress.salePrice != null) ...[
                Text("PKR: ${widget.dress.salePrice!.toStringAsFixed(2)}", style: TextStyle(color: Colors.pink, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("PKR: ${widget.dress.originalPrice.toStringAsFixed(2)}", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                if (widget.dress.discountPercentage != null)
                  Text("${widget.dress.discountPercentage!.toStringAsFixed(1)}% off", style: TextStyle(color: Colors.green, fontSize: 16)),
              ] else ...[
                Text("PKR: ${widget.dress.originalPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
              SizedBox(height: 12),

              // Reward Points
              Text("Reward Points: ${widget.dress.rewardPoints}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 12),
              Row(
                children: [
                  Text("Overall Rating: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(generalRating.toStringAsFixed(1), style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text("($ratingCount ratings)", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 12),
              // Size Selection
              Text("Available Sizes:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: widget.dress.sizes.map((size) {
                  return ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedSize = size;
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 12),
              Text("Available Colors:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: widget.dress.colors.map((color) {
                  return ChoiceChip(
                    label: Text(color),
                    selected: selectedColor == color,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),

              // Add to Cart Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => addToCart(widget.dress, selectedSize!, selectedColor!),
                  icon: Icon(Icons.shopping_cart),
                  label: Text("Add to Cart", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              Divider(height: 32, thickness: 1),
              // General Rating


              // Rating System
              Text("Rate this dress:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon((index < userRating) ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => updateRating((index + 1).toDouble()),
                  );
                }),
              ),
              SizedBox(height: 12),

              // Review Section
              Text("Customer Reviews:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              // Scrollable Review Container
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review['name'] ?? 'Anonymous', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(review['review'] ?? 'No review provided'),
                          Divider(color: Colors.grey.shade300),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Add Review
              TextField(
                controller: reviewController,
                decoration: InputDecoration(
                  hintText: "Write a review...",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.pink), onPressed: submitReview),
                ),
              ),
              SizedBox(height: 20),


            ],
          ),
        ),
      ),
    );
  }
}
