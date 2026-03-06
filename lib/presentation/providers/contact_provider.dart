import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/contact_service.dart';
import '../../data/services/google_contacts_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/user_repository.dart';

class ContactProvider with ChangeNotifier {
  final ContactService _contactService = ContactService();
  final UserRepository _userRepository = UserRepository();

  List<Contact> _phoneContacts = [];
  List<UserEntity> _appUsersFromContacts = [];
  List<UserEntity> _appUsersFromGoogle  = [];
  List<Map<String, dynamic>> _googleContacts = [];
  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  bool _permissionDenied = false;

  List<Contact>    get phoneContacts          => _phoneContacts;
  List<UserEntity> get appUsersFromContacts   => _appUsersFromContacts;
  List<UserEntity> get appUsersFromGoogle     => _appUsersFromGoogle;
  List<Map<String, dynamic>> get googleContacts => _googleContacts;
  bool get isLoading        => _isLoading;
  bool get isGoogleLoading  => _isGoogleLoading;
  bool get permissionDenied => _permissionDenied;

  // Combined unique list used by UI
  List<UserEntity> get allKnownUsers {
    final seen = <String>{};
    return [..._appUsersFromContacts, ..._appUsersFromGoogle]
        .where((u) => seen.add(u.uid))
        .toList();
  }

  Future<void> syncContacts() async {
    _isLoading = true;
    _permissionDenied = false;
    notifyListeners();

    try {
      if (kIsWeb) {
        _isLoading = false;
        notifyListeners();
        return; // Phone contacts not supported on web
      }

      final hasPermission = await _contactService.requestPermission();
      if (!hasPermission) {
        _permissionDenied = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _phoneContacts = await _contactService.getContacts();
      
      // Filter out contacts without phone numbers
      final contactsWithPhone = _phoneContacts.where((c) => c.phones.isNotEmpty).toList();
      
      // Get all app users to match
      final allAppUsers = await _userRepository.getAllUsers();
      
      _appUsersFromContacts = [];
      for (var appUser in allAppUsers) {
        // Match by phone number if available
        bool isMatch = false;
        if (appUser.phoneNumber.isNotEmpty) {
          final normalizedAppUserPhone = _contactService.normalizePhoneNumber(appUser.phoneNumber);
          isMatch = contactsWithPhone.any((contact) {
            return contact.phones.any((phone) {
              return _contactService.normalizePhoneNumber(phone.number) == normalizedAppUserPhone;
            });
          });
        }
        
        // Fallback to name matching if phone didn't match or wasn't available
        if (!isMatch) {
          isMatch = contactsWithPhone.any((contact) {
            return contact.displayName.toLowerCase() == appUser.displayName.toLowerCase();
          });
        }

        if (isMatch) {
          _appUsersFromContacts.add(appUser);
        }
      }

      // Remove app users from phone contacts list for "Invite" section
      _phoneContacts = _phoneContacts.where((contact) {
        return !_appUsersFromContacts.any((u) => 
          u.displayName.toLowerCase() == contact.displayName.toLowerCase() ||
          (u.phoneNumber.isNotEmpty && contact.phones.any((p) => 
            _contactService.normalizePhoneNumber(p.number) == _contactService.normalizePhoneNumber(u.phoneNumber)
          ))
        );
      }).toList();

    } catch (e) {
      debugPrint("Error syncing contacts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  } // end syncContacts

  String? _googleSyncError;
  String? get googleSyncError => _googleSyncError;

  Future<void> syncGoogleContacts() async {
    _isGoogleLoading = true;
    _googleSyncError = null;
    notifyListeners();

    try {
      final googleContactsRaw = await GoogleContactsService.fetchContacts();
      if (googleContactsRaw.isEmpty) {
        _googleSyncError = "No contacts found or permission denied.";
        _isGoogleLoading = false;
        notifyListeners();
        return;
      }

      final allAppUsers = await _userRepository.getAllUsers();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      _appUsersFromGoogle = [];
      _googleContacts = List.from(googleContactsRaw);

      for (final appUser in allAppUsers) {
        if (appUser.uid == currentUserId) continue; // Skip current user

        bool matched = false;

        for (final gc in googleContactsRaw) {
          // Match by email
          final gcEmails = (gc['emails'] as List<String>);
          if (appUser.email.isNotEmpty && gcEmails.any((e) => e.toLowerCase() == appUser.email.toLowerCase())) {
            matched = true;
            break;
          }

          // Match by phone
          final gcPhones = (gc['phones'] as List<String>);
          if (appUser.phoneNumber.isNotEmpty) {
            final normalised = _contactService.normalizePhoneNumber(appUser.phoneNumber);
            if (gcPhones.any((p) => _contactService.normalizePhoneNumber(p).endsWith(normalised) || normalised.endsWith(_contactService.normalizePhoneNumber(p)))) {
              matched = true;
              break;
            }
          }
        }

        if (matched && !_appUsersFromContacts.any((u) => u.uid == appUser.uid)) {
          _appUsersFromGoogle.add(appUser);
        }
      }

      // Remove matched users from the "Invite" Google contacts list
      _googleContacts = _googleContacts.where((gc) {
        final gcEmails = (gc['emails'] as List<String>);
        final gcPhones = (gc['phones'] as List<String>);
        
        // Also remove if the contact is the current user
        final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        final currentUserPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
        
        bool isCurrentUser = (currentUserEmail.isNotEmpty && gcEmails.any((e) => e.toLowerCase() == currentUserEmail.toLowerCase())) ||
                             (currentUserPhone.isNotEmpty && gcPhones.any((p) => _contactService.normalizePhoneNumber(p).endsWith(_contactService.normalizePhoneNumber(currentUserPhone))));
        
        if (isCurrentUser) return false;

        bool isAlreadyAppUser = _appUsersFromGoogle.any((u) => 
          (u.email.isNotEmpty && gcEmails.any((e) => e.toLowerCase() == u.email.toLowerCase())) ||
          (u.phoneNumber.isNotEmpty && gcPhones.any((p) {
              final normApp = _contactService.normalizePhoneNumber(u.phoneNumber);
              final normP = _contactService.normalizePhoneNumber(p);
              return normApp.isNotEmpty && normP.isNotEmpty && (normP.endsWith(normApp) || normApp.endsWith(normP));
          }))
        ) || _appUsersFromContacts.any((u) => 
          (u.email.isNotEmpty && gcEmails.any((e) => e.toLowerCase() == u.email.toLowerCase())) ||
          (u.phoneNumber.isNotEmpty && gcPhones.any((p) {
              final normApp = _contactService.normalizePhoneNumber(u.phoneNumber);
              final normP = _contactService.normalizePhoneNumber(p);
              return normApp.isNotEmpty && normP.isNotEmpty && (normP.endsWith(normApp) || normApp.endsWith(normP));
          }))
        );
        
        return !isAlreadyAppUser;
      }).toList();

      debugPrint('ContactProvider: ${_appUsersFromGoogle.length} users matched from Google Contacts, ${_googleContacts.length} to invite.');
    } catch (e) {
      debugPrint('ContactProvider: Google contacts sync error: $e');
      _googleSyncError = e.toString();
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }
}
