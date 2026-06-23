import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthClient {
  static const _domain = 'trial-8077266.okta.com';
  static const _clientId = 'YOUR_CLIENT_ID';
  static const _redirectUri = 'com.okta.trial-8077266:/callback';
  static const _apiToken = 'YOUR_OKTA_API_TOKEN';

  // Builds a PKCE-secured authorization URL and opens it in an in-app browser.
  Future<void> loginRedirect() async {
    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);
    final state = _generateState();

    final uri = Uri.https(_domain, '/oauth2/default/v1/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'scope': 'openid profile email',
      'redirect_uri': _redirectUri,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch login URL');
    }
  }

  // Registers a new user via the Okta Users API and activates the account immediately.
  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.https(_domain, '/api/v1/users', {'activate': 'true'}),
      headers: {
        'Authorization': 'SSWS $_apiToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'profile': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'login': email,
        },
        'credentials': {
          'password': {'value': password},
        },
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['errorSummary'] ?? 'Registration failed');
    }
  }

  // Generates a cryptographically random base64url-encoded PKCE code verifier.
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  // Derives the PKCE code challenge by SHA-256 hashing and base64url-encoding the verifier.
  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  // Generates a random opaque state value to protect against CSRF in the OAuth flow.
  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
