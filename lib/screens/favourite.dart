import 'package:clothing_store/screens/product_detail.dart';
import 'package:flutter/material.dart';
import '../models/dress.dart';

class FavoriteScreen extends StatefulWidget {
  final List<Dress> favoriteDresses;
  final Function(String) onRemoveFavorite;

  FavoriteScreen({required this.favoriteDresses, required this.onRemoveFavorite});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  late List<Dress> favoriteDresses;

  @override
  void initState() {
    super.initState();
    favoriteDresses = List.from(widget.favoriteDresses); // Create a copy to avoid modifying the original list
  }

  void removeFromFavorites(String dressId) {
    setState(() {
      favoriteDresses.removeWhere((dress) => dress.id == dressId);
      widget.onRemoveFavorite(dressId);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Favorites'),

      ),
      body:  favoriteDresses.isEmpty
    ? Center(
        child: Text(
          'No favorites added yet!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getColumnCount(context),
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.65,
          ),
          itemCount: favoriteDresses.length,
          itemBuilder: (context, index) {
            Dress dress = favoriteDresses[index];
            return _buildFavoriteItem(context, dress);
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Dress dress) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(dress: dress)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    child: Image.asset(
                      dress.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dress.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurpleAccent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Category: ${dress.category}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      Text(
                        'Fabric: ${dress.material}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'PKR: ${dress.isOnSale ? dress.salePrice!.toStringAsFixed(2) : dress.originalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: dress.isOnSale ? Colors.pink : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dress.isOnSale)
                        Text(
                          'PKR: ${dress.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (dress.isOnSale)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SALE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.favorite, color: Colors.red, size: 18),
                  onPressed: () => removeFromFavorites(dress.id),

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int getColumnCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }
}
