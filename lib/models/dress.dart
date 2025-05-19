import 'package:cloud_firestore/cloud_firestore.dart';

class Dress {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String material;
  final double originalPrice;
  final double? salePrice;
  final int popularity;
  final bool recommended;
  final bool isOnSale;
  final String imageUrl;
  final int stock;
  final double rating;
  final int reviewCount;
  final List<String> sizes;
  final List<String> colors;
  final int rewardPoints;
  final String? discountTagline;
  final DateTime createdAt;

  Dress({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.material,
    required this.originalPrice,
    this.salePrice,
    required this.popularity,
    required this.recommended,
    required this.isOnSale,
    required this.imageUrl,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.sizes,
    required this.colors,
    required this.rewardPoints,
    this.discountTagline,
    required this.createdAt,
  });

  /// Convert Firestore document to Dress object
  factory Dress.fromFirestore(Map<String, dynamic> data, String dressId) {
    return Dress(
      id: dressId,
      name: data['name'],
      category: data['category'],
      brand: data['brand'],
      material: data['material'],
      originalPrice: data['originalPrice'],
      salePrice: data['salePrice'],
      popularity: data['popularity'],
      recommended: data['recommended'],
      isOnSale: data['isOnSale'],
      imageUrl: data['imageUrl'],
      stock: data['stock'],
      rating: data['rating'],
      reviewCount: data['reviewCount'],
      sizes: List<String>.from(data['sizes']),
      colors: List<String>.from(data['colors']),
      rewardPoints: data['rewardPoints'],
      discountTagline: data['discountTagline'],
      createdAt: (data['createdAt'] as Timestamp).toDate(), // ✅ Correctly converting Timestamp to DateTime
    );
  }

  /// Convert Dress object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "category": category,
      "brand": brand,
      "material": material,
      "originalPrice": originalPrice,
      "salePrice": salePrice,
      "popularity": popularity,
      "recommended": recommended,
      "isOnSale": isOnSale,
      "imageUrl": imageUrl,
      "stock": stock,
      "rating": rating,
      "reviewCount": reviewCount,
      "sizes": sizes,
      "colors": colors,
      "rewardPoints": rewardPoints,
      "discountTagline": discountTagline,
      "createdAt": Timestamp.fromDate(createdAt), // ✅ Correctly storing as Firestore Timestamp
    };
  }

  /// Calculate discount percentage
  double? get discountPercentage {
    if (salePrice != null) {
      return ((originalPrice - salePrice!) / originalPrice) * 100;
    }
    return null;
  }
}


final List<Dress> dresses = [
  Dress(
    id: '1',
    name: 'Winter Coat',
    category: 'Winter',
    brand: 'Fashion Hub',
    material: 'Wool',
    originalPrice: 120.0,
    salePrice: 100.0,
    popularity: 80,
    recommended: true,
    imageUrl: 'assets/images/2.jpg',
    isOnSale: true,
    stock: 15,
    rating: 4.5,
    reviewCount: 120,
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Black', 'Gray', 'Navy Blue'],
    rewardPoints: 10,
    discountTagline: 'Limited Time: 20% Off!', createdAt: DateTime(1),
  ),
  Dress(
    id: '2',
    name: 'Summer Dress',
    category: 'Summer',
    brand: 'Elegant Wear',
    material: 'Cotton',
    originalPrice: 80.0,
    salePrice: 70.0,
    popularity: 60,
    recommended: false,
    imageUrl: 'assets/images/4.jpg',
    isOnSale: true,
    stock: 30,
    rating: 4.2,
    reviewCount: 85,
    sizes: ['S', 'M', 'L'],
    colors: ['Red', 'Yellow', 'White'],
    rewardPoints: 8,
    discountTagline: 'Hot Sale! Grab Now!',
      createdAt: DateTime(1)
  ),
  Dress(
    id: '3',
    name: 'Khadar Kurta',
    category: 'Khadar',
    brand: 'Desi Vibes',
    material: 'Khadar',
    originalPrice: 50.0,
    salePrice: null,
    popularity: 70,
    recommended: true,
    imageUrl: 'assets/images/3.jpg',
    isOnSale: false,
    stock: 10,
    rating: 4.7,
    reviewCount: 60,
    sizes: ['M', 'L', 'XL'],
    colors: ['Brown', 'Beige'],
    rewardPoints: 5,
      createdAt: DateTime(1)
  ),
  Dress(
    id: '4',
    name: 'Linen Shirt',
    category: 'Linen',
    brand: 'Urban Style',
    material: 'Linen',
    originalPrice: 100.0,
    salePrice: null,
    popularity: 75,
    recommended: false,
    imageUrl: 'assets/images/1.jpg',
    isOnSale: false,
    stock: 0,  // Out of stock
    rating: 4.3,
    reviewCount: 45,
    sizes: ['M', 'L', 'XL'],
    colors: ['White', 'Blue', 'Green'],
    rewardPoints: 7,createdAt: DateTime(1)
  ),
  Dress(
    id: '5',
    name: 'Party Gown',
    category: 'Party Wear',
    brand: 'Glamour Attire',
    material: 'Silk',
    originalPrice: 150.0,
    salePrice: 120.0,
    popularity: 90,
    recommended: true,
    imageUrl: 'assets/images/5.jpg',
    isOnSale: true,
    stock: 20,
    rating: 4.9,
    reviewCount: 150,
    sizes: ['S', 'M', 'L'],
    colors: ['Pink', 'Gold', 'Maroon'],
    rewardPoints: 15,
    discountTagline: 'Steal the Show with 30% Off!',
      createdAt: DateTime(1)
  ),
  Dress(
    id: '6',
    name: 'Casual Top',
    category: 'Ready to Wear',
    brand: 'Trendy Vibes',
    material: 'Cotton Blend',
    originalPrice: 40.0,
    salePrice: 30.0,
    popularity: 65,
    recommended: false,
    imageUrl: 'assets/images/6.jpg',
    isOnSale: true,
    stock: 25,
    rating: 4.1,
    reviewCount: 90,
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['Black', 'White', 'Blue'],
    rewardPoints: 6,
    discountTagline: 'Flash Sale: Save 25%!',
      createdAt: DateTime(1)
  ),
  Dress(
    id: '7',
    name: 'Elegant Maxi',
    category: 'Party Wear',
    brand: 'Royal Couture',
    material: 'Chiffon',
    originalPrice: 200.0,
    salePrice: null,
    popularity: 85,
    recommended: true,
    imageUrl: 'assets/images/7.jpg',
    isOnSale: false,
    stock: 0,  // Out of stock
    rating: 4.8,
    reviewCount: 130,
    sizes: ['S', 'M', 'L'],
    colors: ['Navy Blue', 'Purple'],
    rewardPoints: 12,
      createdAt: DateTime(1)
  ),
  Dress(
    id: '8',
    name: 'Casual Pants',
    category: 'Linen',
    brand: 'Comfy Wear',
    material: 'Linen-Cotton',
    originalPrice: 70.0,
    salePrice: 60.0,
    popularity: 50,
    recommended: false,
    imageUrl: 'assets/images/8.jpg',
    isOnSale: true,
    stock: 18,
    rating: 4.0,
    reviewCount: 75,
    sizes: ['M', 'L', 'XL'],
    colors: ['Gray', 'Black'],
    rewardPoints: 9,
    discountTagline: 'Save 15% Now!',
      createdAt: DateTime(1)
  ),
  Dress(
    id: '9',
    name: 'Classic Blazer',
    category: 'Winter',
    brand: 'Executive Look',
    material: 'Wool Blend',
    originalPrice: 180.0,
    salePrice: null,
    popularity: 95,
    recommended: true,
    imageUrl: 'assets/images/9.jpg',
    isOnSale: false,
    stock: 12,
    rating: 4.9,
    reviewCount: 200,
    sizes: ['M', 'L', 'XL'],
    colors: ['Black', 'Navy Blue'],
    rewardPoints: 20,
      createdAt: DateTime(1)
  ),
  Dress(
    id: '10',
    name: 'Silk Saree',
    category: 'Party Wear',
    brand: 'Ethnic Elegance',
    material: 'Pure Silk',
    originalPrice: 250.0,
    salePrice: 200.0,
    popularity: 100,
    recommended: true,
    imageUrl: 'assets/images/10.jpg',
    isOnSale: true,
    stock: 10,
    rating: 5.0,
    reviewCount: 180,
    sizes: ['Free Size'],
    colors: ['Red', 'Gold', 'Green'],
    rewardPoints: 25,
    discountTagline: 'Special Offer: Save \$50!',createdAt: DateTime(1)
  ),
];
