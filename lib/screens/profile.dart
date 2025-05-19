import 'package:clothing_store/screens/order_history.dart';
import 'package:clothing_store/screens/profile_settings_screen.dart';
import 'package:clothing_store/screens/reward_point.dart';
import 'package:clothing_store/screens/wallet_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/theme_ptovider.dart';
import 'help_support_screen.dart';


class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedIndex = 0;
  double walletBalance = 5000.00;
  int rewardPoints = 120;

  late final List<Widget> _sections; // Declare it as late
  @override
  void initState() {
    super.initState();
    _sections = [
      _buildProfileSection(),
      _buildOrderHistorySection(),
      _buildWalletSection(),
      _buildRewardPointsSection(),
      _buildHelpSupportSection(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> _titles = [
      'Profile & Settings',
      'Order History',
      'Wallet',
      'Reward Points',
      'Help & Support',
    ];
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode; //
    return Scaffold(

      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Dynamically change the title
        backgroundColor: isDarkMode?Colors.black38:Colors.deepPurpleAccent,
      ),
      body: _sections.isNotEmpty
          ? _sections[_selectedIndex]
          : Center(child: CircularProgressIndicator()),
      // Avoid accessing an empty list
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey[700],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileSection() {
    return ProfileSettingsScreen();
  }


  Widget _buildOrderHistorySection() {
    return OrderHistoryScreen();
  }

  Widget _buildWalletSection() {
    return Wallet();
  }


  Widget _buildRewardPointsSection() {

    return RewardPointsPage();
  }

  Widget _buildHelpSupportSection() {
    return HelpSupportScreen();
  }
}
