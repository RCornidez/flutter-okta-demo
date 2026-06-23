import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../env/environment_state.dart';

class AuthClient {
  AuthClient(this._env);

  final EnvironmentState _env;
  String? _codeVerifier;

  // Builds a PKCE-secured authorization URL and opens it in an in-app browser.
  Future<void> loginRedirect() async {
    _codeVerifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(_codeVerifier!);
    final state = _generateState();

    final uri = Uri.https(_env.domain, '/oauth2/default/v1/authorize', {
      'client_id': _env.clientId,
      'response_type': 'code',
      'scope': 'openid profile email',
      'redirect_uri': _env.redirectUri,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch login URL');
    }
  }

  // Exchanges the authorization code from the callback URI for tokens using the stored PKCE verifier.
  Future<Map<String, dynamic>> handleCallback(String callbackUrl) async {
    final uri = Uri.parse(callbackUrl);
    final code = uri.queryParameters['code'];
    if (code == null) throw Exception('No authorization code in callback');
    if (_codeVerifier == null) throw Exception('Missing code verifier');

    final response = await http.post(
      Uri.https(_env.domain, '/oauth2/default/v1/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _env.redirectUri,
        'client_id': _env.clientId,
        'code_verifier': _codeVerifier!,
      },
    );

    _codeVerifier = null;

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error_description'] ?? 'Token exchange failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Registers a new user via the Okta Users API and activates the account immediately.
  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.https(_env.domain, '/api/v1/users', {'activate': 'true'}),
      headers: {
        'Authorization': 'SSWS ${_env.apiToken}',
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
