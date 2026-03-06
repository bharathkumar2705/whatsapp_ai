import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _phoneController = TextEditingController();
  final _nameController  = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final UserRepository _repo = UserRepository();

  UserEntity? _found;
  bool _searching = false;
  bool _searched  = false;
  String? _error;

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _searching = true; _searched = false; _found = null; _error = null; });

    final phone = _phoneController.text.trim();
    // Normalise: ensure it includes country code
    final normalized = phone.startsWith('+') ? phone : '+91$phone';
    final user = await _repo.getUserByPhone(normalized)
               ?? await _repo.getUserByPhone(phone);

    setState(() {
      _searching = false;
      _searched  = true;
      _found     = user;
      if (user == null) _error = 'No WhatsApp account found for this number.';
    });
  }

  Future<void> _saveContact() async {
    if (_found == null) return;
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _found!.displayName;

    // Save into Firestore contacts sub-collection (lightweight — just uid + name)
    await FirebaseFirestore.instance
        .collection('contacts')
        .doc(_found!.uid)
        .set({'uid': _found!.uid, 'savedName': name, 'phone': _found!.phoneNumber});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added to contacts!')),
      );
      Navigator.pop(context, _found);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Phone number ───────────────────────────────────────────
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+91 XXXXX XXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a phone number' : null,
              ),
              const SizedBox(height: 12),

              // ── Name (optional) ─────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name (optional)',
                  hintText: 'How should we display this contact?',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // ── Search button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: Text(_searching ? 'Searching…' : 'Search'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Result ───────────────────────────────────────────────────
              if (_searched) ...[
                if (_found != null) ...[
                  // Found user card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: _found!.photoUrl.isNotEmpty
                              ? NetworkImage(_found!.photoUrl) : null,
                          child: _found!.photoUrl.isEmpty
                              ? const Icon(Icons.person, size: 28) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_found!.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(_found!.phoneNumber,
                                  style: TextStyle(color: scheme.onSurface.withOpacity(0.6))),
                              Text(_found!.about,
                                  style: TextStyle(color: scheme.onSurface.withOpacity(0.5), fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: scheme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveContact,
                      icon: const Icon(Icons.person_add),
                      label: Text('Add ${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : _found!.displayName}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.person_off_outlined, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_error ?? 'Not found',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text('Make sure they have a WhatsApp account\nand signed up with that phone number.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
