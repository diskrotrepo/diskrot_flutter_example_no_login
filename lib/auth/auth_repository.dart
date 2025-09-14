import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_no_login/configuration/configuration.dart';
import 'package:flutter_no_login/dependency_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  AuthRepository();

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('local_id');
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('display_name');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id_token');
    await prefs.remove('refresh_token');
    await prefs.remove('email');
    await prefs.remove('expires_in');
    await prefs.remove('display_name');
    await prefs.remove('local_id');
  }

  Future<void> loginAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    final cfg = di.get<Configuration>();
    final tokenUri = cfg.secure
        ? Uri.https(cfg.apiHost, '/v1/authentication/token')
        : Uri.http(cfg.apiHost, '/v1/authentication/token');

    final body = {
      'grant_type': 'anonymous',
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
  }
}
