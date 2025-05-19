import 'package:flutter/material.dart';
import 'package:clothing_store/widgets/search.dart';
import 'package:provider/provider.dart';
import '../state_management/cart_provider.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String activeCategory;
  final Function(String) onCategorySelected;
  final int favoritesCount;
  final VoidCallback onFavoritesPressed;
  final int cartCount;
  final VoidCallback onCartPressed;

  final String activeDrawerSection;
  final Function(String) onDrawerSectionChange;

  TopNavigationBar({
    required this.activeCategory,
    required this.onCategorySelected,
    required this.favoritesCount,
    required this.onFavoritesPressed,
    required this.cartCount,
    required this.onCartPressed,
    required this.activeDrawerSection,
    required this.onDrawerSectionChange,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 120,
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo or Brand Image
          ClipOval(
            child: Image.asset(
              'assets/images/image.jpg',
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),

          // Icons Row
          Row(
            children: [
              // Search Icon
              GestureDetector(
                onTap: () => showSearchBottomSheet(context),
                child: Icon(Icons.search),
              ),
              SizedBox(width: 10),

              // Profile Icon
              GestureDetector(
                onTap: () {
                  onDrawerSectionChange('profile'); // Set active section to profile
                  Scaffold.of(context).openEndDrawer(); // Open drawer
                },
                child: Icon(Icons.person_4_outlined),
              ),
              SizedBox(width: 10),

              // Favorites Icon with Count
              GestureDetector(
                onTap: onFavoritesPressed,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.favorite_border),
                    if (favoritesCount > 0)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            favoritesCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 10),

              // Cart Icon with Count
              // Cart Icon with Count
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  int itemCount = cartProvider.cartItems.length;

                  return GestureDetector(
                    onTap: () {
                      onDrawerSectionChange('cart'); // Set active section to cart
                      onCartPressed(); // Navigate to cart
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.shopping_cart_outlined),
                        if (itemCount > 0)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                itemCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(120);

  // Search Bottom Sheet
  void showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SearchBottomSheet(),
    );
  }
}
