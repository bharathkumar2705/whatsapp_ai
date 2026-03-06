import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Fetches the signed-in user's Google Contacts via the People API.
/// Only works on mobile. On web, returns empty list gracefully.
class GoogleContactsService {
  static const String _webClientId =
      '693917534702-ibpon4kkjr9h2m59adcsotm96j4dgrbc.apps.googleusercontent.com';

  static GoogleSignIn? _instance;

  static GoogleSignIn get _googleSignIn {
    _instance ??= GoogleSignIn(
      clientId: kIsWeb ? _webClientId : null,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    return _instance!;
  }

  /// Returns the access token, or null on failure.
  static Future<String?> _getAccessToken() async {
    if (kIsWeb && _webClientId.contains('REPLACE_WITH')) {
      debugPrint('GoogleContactsService: Web Client ID not configured.');
      return null;
    }
    try {
      debugPrint('GoogleContactsService: Attempting sign-in...');
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        debugPrint('GoogleContactsService: Silent sign-in failed, prompting...');
        account = await _googleSignIn.signIn();
      }
      
      if (account == null) {
        debugPrint('GoogleContactsService: User cancelled sign-in.');
        return null;
      }
      
      debugPrint('GoogleContactsService: User signed in: ${account.email}');
      
      // On web, sometimes we need to request permissions explicitly if token is missing
      final canAccess = await _googleSignIn.canAccessScopes(_googleSignIn.scopes);
      if (!canAccess) {
        debugPrint('GoogleContactsService: Requesting additional scopes...');
        final authorized = await _googleSignIn.requestScopes(_googleSignIn.scopes);
        if (!authorized) {
          debugPrint('GoogleContactsService: Scope authorization failed.');
          return null;
        }
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        debugPrint('GoogleContactsService: Authentication successful but Access Token is NULL.');
        // If ID token exists but no Access Token, we might be in 'authentication-only' mode
        if (auth.idToken != null) {
          debugPrint('GoogleContactsService: Received ID Token only. This usually means the client ID in index.html or the service is not configured for full offline access or specific authorization.');
        }
      }
      
      return auth.accessToken;
    } catch (e) {
      debugPrint('GoogleContactsService: auth error: $e');
      return null;
    }
  }

  /// Returns a list of contacts from Google People API.
  /// Each entry: { 'name': String, 'emails': List<String>, 'phones': List<String> }
  static Future<List<Map<String, dynamic>>> fetchContacts() async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint('GoogleContactsService: no access token');
      return [];
    }

    final List<Map<String, dynamic>> contacts = [];
    String? nextPageToken;

    do {
      final uri = Uri.https('people.googleapis.com', '/v1/people/me/connections', {
        'personFields': 'names,emailAddresses,phoneNumbers',
        'pageSize': '1000',
        if (nextPageToken != null) 'pageToken': nextPageToken,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        debugPrint('GoogleContactsService: API error ${response.statusCode}: ${response.body}');
        break;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      nextPageToken = data['nextPageToken'] as String?;

      final connections = (data['connections'] as List<dynamic>?) ?? [];
      for (final person in connections) {
        final p = person as Map<String, dynamic>;

        // Names
        final names = (p['names'] as List<dynamic>?) ?? [];
        final name = names.isNotEmpty
            ? (names.first['displayName'] as String? ?? '')
            : '';

        // Emails
        final emailObjs = (p['emailAddresses'] as List<dynamic>?) ?? [];
        final emails = emailObjs
            .map((e) => (e as Map<String, dynamic>)['value'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

        // Phones
        final phoneObjs = (p['phoneNumbers'] as List<dynamic>?) ?? [];
        final phones = phoneObjs
            .map((e) => (e as Map<String, dynamic>)['value'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

        if (name.isNotEmpty || emails.isNotEmpty || phones.isNotEmpty) {
          contacts.add({'name': name, 'emails': emails, 'phones': phones});
        }
      }
    } while (nextPageToken != null);

    debugPrint('GoogleContactsService: fetched ${contacts.length} contacts');
    return contacts;
  }
}
