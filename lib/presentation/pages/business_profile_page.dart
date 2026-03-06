import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _greetingController = TextEditingController();
  final _awayController = TextEditingController();
  bool _isBusiness = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _addressController.text = user.businessAddress ?? '';
      _websiteController.text = user.businessWebsite ?? '';
      _greetingController.text = user.greetingMessage ?? '';
      _awayController.text = user.awayMessage ?? '';
      _isBusiness = user.isBusiness;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Profile"),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Business Account"),
            subtitle: const Text("Enable business features for this account"),
            value: _isBusiness,
            activeColor: const Color(0xFF00A884),
            onChanged: (val) => setState(() => _isBusiness = val),
          ),
          const Divider(),
          if (_isBusiness) ...[
            _buildSectionTitle("Profile Details"),
            _buildTextField("Address", _addressController, Icons.location_on),
            _buildTextField("Website", _websiteController, Icons.language),
            const SizedBox(height: 24),
            _buildSectionTitle("Automated Messages"),
            _buildTextField("Greeting Message", _greetingController, Icons.waving_hand, 
              hint: "Sent when customers message you for the first time"),
            _buildTextField("Away Message", _awayController, Icons.timer_outlined,
              hint: "Sent when you are unavailable"),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.blue),
              title: const Text("Meta Verified"),
              subtitle: const Text("Business verification status"),
              trailing: Consumer<AuthProvider>(
                builder: (context, auth, _) => Text(
                  auth.userModel?.isVerified == true ? "VERIFIED" : "NOT VERIFIED",
                  style: TextStyle(
                    color: auth.userModel?.isVerified == true ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(
        color: Color(0xFF00A884),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      )),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        maxLines: label.contains("Message") ? 3 : 1,
      ),
    );
  }

  void _saveProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updateBusinessProfile({
      'isBusiness': _isBusiness,
      'businessAddress': _addressController.text,
      'businessWebsite': _websiteController.text,
      'greetingMessage': _greetingController.text,
      'awayMessage': _awayController.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Business profile updated!")),
      );
      Navigator.pop(context);
    }
  }
}
