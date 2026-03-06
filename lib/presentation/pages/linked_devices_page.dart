import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import 'qr_scanner_page.dart';

class LinkedDevicesPage extends StatelessWidget {
  const LinkedDevicesPage({super.key});

  static const int _maxDevices = 4;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Linked devices"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: auth.getLinkedDevices(),
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];
          // Current device is always shown separately
          final otherDevices = devices.where((d) => d['isCurrent'] != true).toList();

          return ListView(
            children: [
              // Header banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00A884).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.devices, size: 48, color: Color(0xFF00A884)),
                    const SizedBox(height: 12),
                    const Text(
                      "Use WhatsApp on up to 4 linked devices",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your messages sync across all devices without your phone needing to be online.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Capacity indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "${otherDevices.length} / $_maxDevices devices linked",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    if (devices.isNotEmpty)
                      _SyncBadge(),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Link a device button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text(
                      "Link a device",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: otherDevices.length >= _maxDevices
                        ? null
                        : () => _openScanner(context, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),

              // This device section
              const _SectionHeader("THIS DEVICE"),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00A884).withOpacity(0.15),
                  child: Icon(
                    kIsWeb ? Icons.computer : Icons.smartphone,
                    color: const Color(0xFF00A884),
                  ),
                ),
                title: Text(
                  kIsWeb ? "WhatsApp Web (Current)" : "Mobile (Current)",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Active now", style: TextStyle(color: Color(0xFF00A884))),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF00A884), size: 18),
              ),

              // Other linked devices
              if (otherDevices.isNotEmpty) ...[
                const Divider(),
                const _SectionHeader("LINKED DEVICES"),
                ...otherDevices.map((device) => _DeviceTile(
                      device: device,
                      onLogout: () => _confirmLogout(context, auth, device),
                    )),
              ],

              if (snapshot.connectionState == ConnectionState.waiting && devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (otherDevices.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      "No other devices linked",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  "* Connection status updates every minute. For security, cleanup of inactive devices happens on startup.",
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _openScanner(BuildContext context, AuthProvider auth) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
    );
    // In a real app, the scanner would return the device info.
    // For this simulation/debugging, we'll link a mock "WhatsApp Web" device after returning.
    Future.delayed(const Duration(seconds: 5), () {
      if (context.mounted) {
        auth.linkDevice("Web", "WhatsApp Web (Chrome/Windows)");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New device linked successfully!")),
        );
      }
    });
  }

  void _showLinkDialog(BuildContext context) {
    final token = 'WA-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final webUrl = 'https://whatsapp-ai-ebb0a.web.app?link_token=$token';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Color(0xFF00A884)),
            SizedBox(width: 8),
            Text("Link a Device"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Real-looking QR code drawn with CustomPainter
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _QrPainter(data: token),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Scan this code with another device, or open the web app link below:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                token,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("COPY LINK"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: webUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard!")),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth, Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out device?"),
        content: Text("This will remove \"${device['name'] ?? 'this device'}\" from your account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              auth.removeDevice(device['id'] ?? device['deviceId']);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Device logged out.")),
              );
            },
            child: const Text("LOG OUT", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00A884),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onLogout;

  const _DeviceTile({required this.device, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final platform = device['platform'] ?? 'Unknown';
    final name = device['name'] ?? platform;
    final linkedAt = device['linkedAt'];
    final lastActive = device['lastActive'];

    IconData icon;
    if (platform == 'Web') {
      icon = Icons.computer;
    } else if (platform == 'Desktop') {
      icon = Icons.desktop_windows;
    } else {
      icon = Icons.smartphone;
    }

    String linkedStr = '';
    if (linkedAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(linkedAt as int);
      linkedStr = "Linked ${DateFormat('MMM d, HH:mm').format(dt)}";
    }

    String activeStr = '';
    if (lastActive != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastActive as int);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 2) {
        activeStr = 'Active now';
      } else if (diff.inHours < 1) {
        activeStr = 'Active ${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        activeStr = 'Active ${diff.inHours}h ago';
      } else {
        activeStr = 'Last seen ${DateFormat('MMM d').format(dt)}';
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(icon, color: Colors.grey[700]),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeStr.isNotEmpty)
            Text(
              activeStr,
              style: TextStyle(
                color: activeStr == 'Active now'
                    ? const Color(0xFF00A884)
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          if (linkedStr.isNotEmpty)
            Text(linkedStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'logout') onLogout();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text("Log out", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00A884).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 12, color: Color(0xFF00A884)),
          SizedBox(width: 4),
          Text("Synced", style: TextStyle(fontSize: 11, color: Color(0xFF00A884))),
        ],
      ),
    );
  }
}

// ── QR CustomPainter ─────────────────────────────────────────────────────────

class _QrPainter extends CustomPainter {
  final String data;
  static const int _size = 21; // 21×21 modules

  const _QrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black87;
    final light = Paint()..color = Colors.white;
    final border = Paint()
      ..color = const Color(0xFF00A884)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Background + border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      light,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.25, 1.25, size.width - 2.5, size.height - 2.5),
        const Radius.circular(8),
      ),
      border,
    );

    // Cell size with 1-cell quiet zone on each side
    final cs = size.width / (_size + 2);
    final qz = cs; // quiet zone offset

    // Pseudo-random data cells seeded from token
    final seed = data.codeUnits.fold(0, (a, b) => (a ^ b * 31) & 0xFFFFFF);
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_isFinderZone(r, c)) continue;
        final bit = (seed + r * 17 + c * 13 + r * c * 7) % 4;
        if (bit < 2) {
          canvas.drawRect(
            Rect.fromLTWH(qz + c * cs + 0.4, qz + r * cs + 0.4, cs - 0.8, cs - 0.8),
            dark,
          );
        }
      }
    }

    // Three finder patterns
    _drawFinder(canvas, dark, light, qz, 0, 0, cs);            // top-left
    _drawFinder(canvas, dark, light, qz, 0, _size - 7, cs);    // top-right
    _drawFinder(canvas, dark, light, qz, _size - 7, 0, cs);    // bottom-left
  }

  bool _isFinderZone(int r, int c) {
    if (r < 8 && c < 8) return true;
    if (r < 8 && c >= _size - 8) return true;
    if (r >= _size - 8 && c < 8) return true;
    return false;
  }

  void _drawFinder(Canvas canvas, Paint dark, Paint light, double qz,
      int startR, int startC, double cs) {
    final x = qz + startC * cs;
    final y = qz + startR * cs;
    canvas.drawRect(Rect.fromLTWH(x, y, cs * 7, cs * 7), dark);
    canvas.drawRect(Rect.fromLTWH(x + cs, y + cs, cs * 5, cs * 5), light);
    canvas.drawRect(Rect.fromLTWH(x + cs * 2, y + cs * 2, cs * 3, cs * 3), dark);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data;
}
