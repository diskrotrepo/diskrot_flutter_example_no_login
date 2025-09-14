// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_no_login/configuration/configuration.dart';
import 'package:flutter_no_login/dependency_context.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    final error = uri.queryParameters.containsKey('error')
        ? uri.queryParameters['error']
        : null;
    final errorDesc = uri.queryParameters.containsKey('error_description')
        ? uri.queryParameters['error_description']
        : null;

    if (error != null) {
      print('OAuth error: $error, description: $errorDesc');
      setState(
          () => _error = '$error${errorDesc != null ? ": $errorDesc" : ""}');
      return;
    }

    if (code == null || code.isEmpty) {
      print('Missing authorization code');
      setState(() => _error = 'Missing authorization code');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final expectedState = prefs.getString('oauth_state');
    await prefs.remove('oauth_state');
    if (expectedState == null || expectedState != returnedState) {
      print(expectedState == null
          ? 'Missing state'
          : 'Invalid state: expected $expectedState, got $returnedState');
      setState(() => _error = 'Invalid state');
      return;
    }

    try {
      final cfg = di.get<Configuration>();
      final tokenUri = cfg.secure
          ? Uri.https(cfg.apiHost, '/v1/authentication/token')
          : Uri.http(cfg.apiHost, '/v1/authentication/token');

      final body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': cfg.redirectUri,
        'client_id': cfg.applicationId,
      };

      final res = await http.post(
        tokenUri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&'),
      );

      if (res.statusCode != 200) {
        print('Token exchange failed (${res.statusCode}): ${res.body}');
        setState(() => _error = 'Token exchange failed (${res.statusCode})');
        return;
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final idToken = json['idToken'] as String;
      final refreshToken = json['refreshToken'] as String;
      final expiresIn = json['expiresIn'].toString();
      final email = json['email'] as String;
      final localId = json['localId'] as String;

      await prefs.setString('id_token', idToken);
      await prefs.setString('expires_in', expiresIn);
      await prefs.setString('email', email);
      await prefs.setString('local_id', localId);
      await prefs.setString('refresh_token', refreshToken);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/app');
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() => _error = 'Unexpected error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
      ),
    );
  }
}
