import 'package:flutter/material.dart';
import '../models/dress.dart';
import '../screens/product_detail.dart';

class ProductGrid extends StatelessWidget {
  final String selectedCategory;
  final String selectedSort;
  final Set<String> favoriteDressIds;
  final Function(String) onToggleFavorite;
  final Function(String) onAddToCart;

  ProductGrid({
    required this.selectedCategory,
    required this.selectedSort,
    required this.favoriteDressIds,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    List<Dress> filteredDresses = selectedCategory == 'All'
        ? dresses
        : dresses.where((dress) => dress.category == selectedCategory).toList();

    switch (selectedSort) {
      case 'low':
        filteredDresses.sort((a, b) =>
        a.salePrice?.compareTo(b.salePrice ?? a.originalPrice) ??
            a.originalPrice.compareTo(b.originalPrice));
        break;
      case 'high':
        filteredDresses.sort((a, b) =>
            (b.salePrice ?? b.originalPrice).compareTo(a.salePrice ?? a.originalPrice));
        break;
      case 'popular':
        filteredDresses.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case 'recommended':
        filteredDresses =
            filteredDresses.where((dress) => dress.recommended).toList();
        break;
      default:
        break;
    }

    double screenWidth = MediaQuery.of(context).size.width;
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getColumnCount(context),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: screenWidth < 600 ? 0.45 : 0.55,
      ),
      itemCount: filteredDresses.length,
      itemBuilder: (context, index) {
        Dress dress = filteredDresses[index];
        bool isFavorite = favoriteDressIds.contains(dress.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(dress: dress),
              ),
            );
          },
          child: Card(
           // color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: screenWidth < 600 ? 6 : 7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                        child: Image.asset(
                          dress.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: screenWidth < 600 ? 4 : 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dress.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurpleAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            if (dress.isOnSale && dress.salePrice != null) ...[
                              Text(
                                'PKR:${dress.salePrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'PKR:${dress.originalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '${dress.discountPercentage!.toStringAsFixed(1)}% off',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'PKR: ${dress.originalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            SizedBox(height: 4),
                            Text(
                              dress.category,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => onToggleFavorite(dress.id),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              /*  Positioned(
                  bottom: 8,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onAddToCart(dress.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.add_shopping_cart_sharp, color: Colors.white),
                    ),
                  ),
                ),*/
              ],
            ),
          ),
        );
      },
    );
  }

  int getColumnCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1000) return 4;
    if (width > 750) return 3;
    return 2;
  }
}
