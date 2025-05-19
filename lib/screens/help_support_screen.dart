import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Launch email client
  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'myoushayousha7@gmail.com',
      query: 'subject=Support Request&body=Hi, I need help with...',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      _showErrorDialog('Email Launch Error',
          'Could not launch email client. Please check your email setup.');
      print('Error launching email: $e');
    }
  }

  // Launch phone dialer
  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '03196348134');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      _showErrorDialog('Phone Dialer Error',
          'Could not launch phone dialer. Please check your phone setup.');
      print('Error launching phone dialer: $e');
    }
  }


  // Error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.poppins()),
          content: Text(message, style: GoogleFonts.roboto()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  // Support tile widget
  Widget _supportTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.blueAccent,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style:
          GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: GoogleFonts.roboto(fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Need Help?",
                style: GoogleFonts.poppins(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Choose a support option below.",
                style: GoogleFonts.roboto(
                    fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 20),



            _supportTile(
              context: context,
              icon: Icons.email_outlined,
              title: "Email Support",
              subtitle: "Send us your queries via email.",
              onTap: _launchEmail,
              color: Colors.redAccent,
            ),
            Divider(),

            _supportTile(
              context: context,
              icon: Icons.call_outlined,
              title: "Call Support",
              subtitle: "Speak directly with customer support.",
              onTap: _launchPhone,
              color: Colors.green,
            ),
            Divider(),

            SizedBox(height: 20),
            Text("FAQs",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: [
                  ExpansionTile(
                    leading:
                    Icon(Icons.local_shipping_outlined, color: Colors.teal),
                    title: Text("How do I track my order?",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Go to 'Orders' in your profile to view tracking details.",
                            style: GoogleFonts.roboto(),
                          ))
                    ],
                  ),
                  ExpansionTile(
                    leading:
                    Icon(Icons.lock_outline, color: Colors.teal),
                    title: Text("How can I reset my password?",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Go to Settings > Change Password to update your credentials.",
                            style: GoogleFonts.roboto(),
                          ))
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.card_giftcard_outlined,
                        color: Colors.teal),
                    title: Text("How do I redeem my reward points?",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Once you have 500+ points, redeem them in the wallet section. ₹500 will be added per 500 points.",
                            style: GoogleFonts.roboto(),
                          ))
                    ],
                  ),
                  ExpansionTile(
                    leading:
                    Icon(Icons.person_outline, color: Colors.teal),
                    title: Text("How to contact support?",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "You can call, email, or use live chat from this screen.",
                            style: GoogleFonts.roboto(),
                          ))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
