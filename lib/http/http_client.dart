import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_no_login/auth/auth_repository.dart';
import 'package:flutter_no_login/configuration/configuration.dart';
import 'package:flutter_no_login/dependency_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiskRotHttpClient {
  final Configuration configuration;
  final apiVersion = 'v1';

  DiskRotHttpClient(this.configuration);

  Future<Map<String, String>> _getHeaders() async {
    final idToken = await di<AuthRepository>().getIdToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $idToken',
      'Diskrot-Project-Id': configuration.applicationId,
    };
  }

  Future<http.Response> get({
    required String endpoint,
    Map<String, dynamic>? query,
  }) async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion$endpoint', query)
        : Uri.http(configuration.apiHost, '$apiVersion$endpoint', query);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 403) {
      await _refreshIdTokenAnonymously();
      return await http.get(
        uri,
        headers: await _getHeaders(),
      );
    }

    return response;
  }

  Future<http.Response> post(
      {required String endpoint, required Map<String, dynamic> data}) async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion$endpoint')
        : Uri.http(configuration.apiHost, '$apiVersion$endpoint');

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 403) {
      await _refreshIdTokenAnonymously();
      return await http.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
    }

    return response;
  }

  Future<http.Response> put(
      {required String endpoint, required Map<String, dynamic> data}) async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion$endpoint')
        : Uri.http(configuration.apiHost, '$apiVersion$endpoint');

    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 403) {
      await _refreshIdTokenAnonymously();
      return await http.put(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
    }

    return response;
  }

  Future<http.Response> delete({required String endpoint}) async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion$endpoint')
        : Uri.http(configuration.apiHost, '$apiVersion$endpoint');

    final response = await http.delete(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 403) {
      await _refreshIdTokenAnonymously();
      return await http.delete(
        uri,
        headers: await _getHeaders(),
      );
    }

    return response;
  }

  // ignore: unused_element
  Future<void> _refreshIdToken() async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion/authentication/refresh')
        : Uri.http(configuration.apiHost, '$apiVersion/authentication/refresh');

    await http
        .post(
      uri,
      headers: {'Accept': 'application/json'},
      body: jsonEncode(
          {'refreshToken': await di<AuthRepository>().getRefreshToken()}),
    )
        .then((refreshResponse) {
      if (refreshResponse.statusCode == 200) {
        final body = jsonDecode(refreshResponse.body);
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('id_token', body['id_token']);
          prefs.setString('access_token', body['access_token']);
          prefs.setString('refresh_token', body['refresh_token']);
          prefs.setString('expires_in', body['expires_in']);
        });
      } else {
        throw Exception('Failed to refresh token');
      }
    });
  }

  Future<void> _refreshIdTokenAnonymously() async {
    final uri = configuration.secure
        ? Uri.https(configuration.apiHost, '$apiVersion/authentication/token')
        : Uri.http(configuration.apiHost, '$apiVersion/authentication/token');

    await http
        .post(
      uri,
      headers: {'Accept': 'application/json'},
      body: jsonEncode({
        'grant_type': 'anonymous',
        'client_id': configuration.applicationId
      }),
    )
        .then((refreshResponse) {
      if (refreshResponse.statusCode == 200) {
        final body = jsonDecode(refreshResponse.body);
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('id_token', body['id_token']);
          prefs.setString('refresh_token', body['refresh_token']);
          prefs.setString('expires_in', body['expires_in']);
        });
      } else {
        throw Exception('Failed to refresh token');
      }
    });
  }
}
