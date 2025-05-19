import 'package:clothing_store/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/cart_provider.dart';

class ResponsiveNavigationBar extends StatelessWidget {
  final String activeDrawerSection;
  final Function(String) onDrawerSectionChange;
  final VoidCallback onFavoritesPressed;
  final VoidCallback onCartPressed;
  final VoidCallback onSearchPressed;
  final int favoritesCount;

  const ResponsiveNavigationBar({
    Key? key,
    required this.activeDrawerSection,
    required this.onDrawerSectionChange,
    required this.onFavoritesPressed,
    required this.onCartPressed,
    required this.onSearchPressed,
    required this.favoritesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: (index) => _handleNavigationTap(index),
      type: BottomNavigationBarType.fixed,
     // backgroundColor: Colors.white,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      items: [
        _buildNavItem(Icons.search, 'Search', onTap: () => showSearchBottomSheet(context)),
        _buildBadgeNavItem(Icons.favorite_border, 'Favorites', favoritesCount, onFavoritesPressed),
        _buildCartNavItem(context),
        _buildNavItem(Icons.person_4_outlined, 'Profile', onTap: () {
          onDrawerSectionChange('profile');
          Scaffold.of(context).openEndDrawer();
        }),
      ],
    );
  }

  /// Generic navigation item (without badge).
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, {required VoidCallback onTap}) {
    return BottomNavigationBarItem(
      icon: GestureDetector(onTap: onTap, child: Icon(icon, size: 28)),
      label: label,
    );
  }

  /// Navigation item with a badge (for favorites).
  BottomNavigationBarItem _buildBadgeNavItem(IconData icon, String label, int badgeCount, VoidCallback onTap) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 28),
            if (badgeCount > 0) _buildBadge(badgeCount),
          ],
        ),
      ),
      label: label,
    );
  }

  /// Navigation item for cart (with dynamic badge from provider).
  BottomNavigationBarItem _buildCartNavItem(BuildContext context) {
    return BottomNavigationBarItem(
      icon: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return GestureDetector(
            onTap: () {
              onDrawerSectionChange('cart');
              onCartPressed();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 28),
                if (cartProvider.cartItems.isNotEmpty)
                  _buildBadge(cartProvider.cartItems.length),
              ],
            ),
          );
        },
      ),
      label: 'Cart',
    );
  }

  /// Badge widget for notification counts.
  Widget _buildBadge(int count) {
    return Positioned(
      right: -5,
      top: -5,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: Text(
          count.toString(),
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Handles bottom navigation selection.
  void _handleNavigationTap(int index) {
    switch (index) {
      case 0:
        onSearchPressed();
        break;
      case 1:
        onFavoritesPressed();
        break;
      case 2:
        onCartPressed();
        break;
      case 3:
        onDrawerSectionChange('profile');
        break;
    }
  }

  /// Determines the currently active index.
  int _getCurrentIndex() {
    return {
      'search': 0,
      'favorites': 1,
      'cart': 2,
      'profile': 3,
    }[activeDrawerSection] ?? 0;
  }
}

/// Shows the search modal.
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
