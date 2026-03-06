import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';
import 'avatar_creation_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploadingPhoto = false;
  static const _green = Color(0xFF00A884);
  static const _darkGreen = Color(0xFF075E54);

  // ── Photo Upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user!.uid;
      final bytes = await picked.readAsBytes();
      final url = await _uploadToStorage(uid, bytes);
      await auth.updateProfile({'photoUrl': url});
      if (mounted) _snack("Profile photo updated ✓");
    } catch (e) {
      if (mounted) _snack("Upload failed: $e");
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<String> _uploadToStorage(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');
    final task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Change profile photo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: _green)),
            title: const Text("Take a photo"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.photo_library, color: Colors.blue)),
            title: const Text("Choose from gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Inline Edit ───────────────────────────────────────────────────────────
  Future<void> _editField({
    required String title,
    required String currentValue,
    required String firestoreKey,
    int maxLines = 1,
    int maxLength = 70,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: true,
          decoration: InputDecoration(
            hintText: title,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _green, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child:
                const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty && result != currentValue) {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.updateProfile({firestoreKey: result});
        if (mounted) _snack("$title updated ✓");
      } catch (e) {
        if (mounted) _snack("Failed to update $title: $e");
      }
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Photo section ───────────────────────────────────────────
            Container(
              width: double.infinity,
              color: _darkGreen.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _uploadingPhoto
                        ? const SizedBox(
                            width: 128,
                            height: 128,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: _green))
                        : UserAvatar(url: user.photoUrl, radius: 64),
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "Tap any field to edit it",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),

            // ── Info tiles ──────────────────────────────────────────────
            _EditTile(
              icon: Icons.person_outline,
              label: "Name",
              value: user.displayName,
              onTap: () => _editField(
                title: "Name",
                currentValue: user.displayName,
                firestoreKey: "displayName",
                maxLength: 25,
              ),
            ),

            _EditTile(
              icon: Icons.info_outline,
              label: "About",
              value: user.about.isEmpty ? "Hey there! I am using WhatsApp." : user.about,
              onTap: () => _editField(
                title: "About",
                currentValue: user.about,
                firestoreKey: "about",
                maxLines: 3,
                maxLength: 139,
              ),
            ),

            _EditTile(
              icon: Icons.phone_outlined,
              label: "Phone Number",
              value: user.phoneNumber.isEmpty ? "Add your phone number" : user.phoneNumber,
              onTap: () => _editField(
                title: "Phone Number",
                currentValue: user.phoneNumber,
                firestoreKey: "phoneNumber",
                maxLength: 20,
              ),
            ),

            // Email is read-only
            _EditTile(
              icon: Icons.email_outlined,
              label: "Email",
              value: user.email.isEmpty ? "—" : user.email,
              onTap: null, // not editable
              showEdit: false,
            ),

            const Divider(height: 32),
            
            // ── Extreme Privacy Section ───────────────────────────────────
            _buildSectionHeader("Extreme Privacy Innovations"),
            
            SwitchListTile(
              secondary: Icon(Icons.visibility_off, color: Colors.deepPurple[400]),
              title: const Text("Ghost Mode"),
              subtitle: const Text("Read messages without blue ticks"),
              activeColor: _green,
              value: user.ghostModeEnabled,
              onChanged: (val) => auth.updateProfile({'ghostModeEnabled': val}),
            ),
            
            SwitchListTile(
              secondary: Icon(Icons.person_search, color: Colors.blueGrey[400]),
              title: const Text("Anonymous Mode"),
              subtitle: const Text("Join groups with a temporary alias"),
              activeColor: _green,
              value: user.isTemporary,
              onChanged: (val) {
                if (val) {
                  final alias = "Secret Agent #${user.uid.substring(0, 4)}";
                  auth.updateProfile({'isTemporary': true, 'displayName': alias});
                } else {
                  auth.updateProfile({'isTemporary': false});
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.auto_delete, color: Colors.red[300]),
              title: const Text("Self-Destruct Profile"),
              subtitle: Text(user.expiresAt == null 
                ? "Account never expires" 
                : "Expires in ${user.expiresAt!.difference(DateTime.now()).inMinutes} minutes"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSelfDestructPicker(context, auth),
            ),

            ListTile(
              leading: const Icon(Icons.verified, color: Colors.purple),
              title: const Text("Blockchain Identity"),
              subtitle: const Text("Decentralized verification status"),
              trailing: user.isDecentralizedVerified 
                ? const Icon(Icons.check_circle, color: Colors.purple) 
                : const Text("Verify Now", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              onTap: user.isDecentralizedVerified ? null : () => _mockBlockchainVerification(context, auth),
            ),

            const Divider(height: 32),

            // ── Avatar ──────────────────────────────────────────────────
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.face, color: Colors.blue)),
              title: const Text("Custom Avatar",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text("Create a cartoon avatar"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AvatarCreationPage())),
            ),

            const Divider(height: 32),

            // ── Log out ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Log Out",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Log out?"),
                        content: const Text("You will need to sign in again."),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("CANCEL")),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text("LOG OUT")),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await Provider.of<AuthProvider>(context, listen: false)
                          .signOut();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

extension _ProfileExtras on _ProfilePageState {
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[600],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showSelfDestructPicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Select Expiration Time", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text("None (Normal Account)"),
            onTap: () {
              auth.updateProfile({'expiresAt': null});
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("24 Hours"),
            onTap: () {
              final date = DateTime.now().add(const Duration(hours: 24));
              auth.updateProfile({'expiresAt': date.millisecondsSinceEpoch});
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("7 Days"),
            onTap: () {
              final date = DateTime.now().add(const Duration(days: 7));
              auth.updateProfile({'expiresAt': date.millisecondsSinceEpoch});
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _mockBlockchainVerification(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          auth.updateProfile({'isDecentralizedVerified': true});
          if (ctx.mounted) Navigator.pop(ctx);
          _snack("Identity verified on Blockchain! 🔑");
        });
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.purple),
              SizedBox(height: 20),
              Text("Connecting to Decentralized ID Network..."),
              SizedBox(height: 8),
              Text("Verifying Proof of Identity...", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable editable list tile
class _EditTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showEdit;

  const _EditTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00A884)),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: showEdit
          ? const Icon(Icons.edit, color: Color(0xFF00A884), size: 18)
          : null,
      onTap: onTap,
    );
  }
}
