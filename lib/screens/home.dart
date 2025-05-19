import 'package:clothing_store/screens/profile.dart';
import 'package:flutter/material.dart';
import '../models/banner.dart';
import '../models/dress.dart';
import '../state_management/cart_provider.dart';
import '../state_management/reward_provider.dart';
import '../state_management/wishlist_provider.dart';  // Import WishlistProvider
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_navigation_bar.dart';
import '../widgets/product_grid.dart';
import 'cart.dart';
import 'favourite.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String selectedSort = 'new';
  final Map<String, int> cart = {};
  String activeDrawerSection = 'profile';

  final List<String> categories = [
    'All',
    'Winter',
    'Summer',
    'Khadar',
    'Linen',
    'Party Wear',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void updateDrawerSection(String section) {
    setState(() {
      activeDrawerSection = section;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  void initState() {
    super.initState();
    initializeRewards();
  }

  void initializeRewards() async {
    final rewardProvider = Provider.of<RewardProvider>(context, listen: false);
    await rewardProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Provider.of<CartProvider>(context, listen: false).initializeCart();

    // Access WishlistProvider to interact with t\
    // he wishlist
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: screenWidth > 600
          ? TopNavigationBar(
        activeCategory: selectedCategory,
        onCategorySelected: (category) {
          setState(() {
            selectedCategory = category;
          });
        },
        favoritesCount: wishlistProvider.wishlist.length,
        onFavoritesPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoriteScreen(
                favoriteDresses: dresses
                    .where((dress) => wishlistProvider.wishlist.contains(dress.id))
                    .toList(),
                onRemoveFavorite: (id) {
                  wishlistProvider.removeFromWishlist(id);
                },
              ),
            ),
          );
        },
        cartCount: cart.values.fold(0, (sum, quantity) => sum + quantity),
        onCartPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        activeDrawerSection: activeDrawerSection,
        onDrawerSectionChange: updateDrawerSection,
      )
          : AppBar(
        title: Text("Ladies Fashion"),
       // backgroundColor: Colors.redAccent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: CarouselSliderWidget(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _FilterHeader(
              screenWidth: screenWidth,
              selectedCategory: selectedCategory,
              selectedSort: selectedSort,
              categories: categories,
              onCategoryChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              onSortChanged: (value) {
                setState(() {
                  selectedSort = value!;
                });
              },
            ),
          ),
          SliverFillRemaining(
            child: ProductGrid(
              selectedCategory: selectedCategory,
              selectedSort: selectedSort,
              favoriteDressIds: wishlistProvider.wishlist,
              onToggleFavorite: (dressId) {
                setState(() {
                  // Add or remove dressId from wishlist
                  wishlistProvider.toggleWishlist(dressId);
                });
              },
              onAddToCart: (dressId) {
                setState(() {
                  cart.update(dressId, (value) => value + 1, ifAbsent: () => 1);
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: screenWidth < 600
          ? ResponsiveNavigationBar(
        activeDrawerSection: activeDrawerSection,
        onDrawerSectionChange: updateDrawerSection,
        favoritesCount: wishlistProvider.wishlist.length,
        onFavoritesPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoriteScreen(
                favoriteDresses: dresses
                    .where((dress) => wishlistProvider.wishlist.contains(dress.id))
                    .toList(),
                onRemoveFavorite: (id) {
                  wishlistProvider.removeFromWishlist(id);
                },
              ),
            ),
          );
        },
        onCartPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        onSearchPressed: () => showSearchBottomSheet(context),
      )
          : null,
      endDrawer: Drawer(
        width: 330,
        child: activeDrawerSection == 'cart'
            ? CartScreen()
            : UserProfileScreen(),
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  final double screenWidth;
  final String selectedCategory;
  final String selectedSort;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSortChanged;

  _FilterHeader({
    required this.screenWidth,
    required this.selectedCategory,
    required this.selectedSort,
    required this.categories,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
     // color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                onChanged: onCategoryChanged,
                items: categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSort,
                onChanged: onSortChanged,
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New Arrival')),
                  DropdownMenuItem(value: 'low', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'high', child: Text('Price: High to Low')),
                  DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                  DropdownMenuItem(value: 'recommended', child: Text('Recommended')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
